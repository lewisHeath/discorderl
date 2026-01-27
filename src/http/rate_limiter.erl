-module(rate_limiter).
-behaviour(gen_server).

%% API
-export([
    start_link/0,
    get_spec/0,
    wait_for_rate_limit/1,
    update_rate_limit/2,
    is_rate_limited/1,
    get_bucket_info/1
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-include("logging.hrl").

-record(state, {}).

-record(bucket, {
    remaining :: non_neg_integer(),
    reset_at :: non_neg_integer(),    %% Unix timestamp in milliseconds
    limit :: non_neg_integer(),
    global :: boolean()
}).

-define(BUCKET_TABLE, rate_limit_buckets).
-define(GLOBAL_KEY, global_rate_limit).
-define(CLEANUP_INTERVAL, 60000). %% Clean expired buckets every minute

%% ==========================================================
%% API
%% ==========================================================

get_spec() ->
    #{
        id => ?MODULE,
        start => {?MODULE, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [?MODULE]
    }.

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec wait_for_rate_limit(string()) -> ok | {wait, non_neg_integer()}.
wait_for_rate_limit(Endpoint) ->
    case config:get_value(rate_limit_enabled, true) of
        false -> ok;
        true -> gen_server:call(?MODULE, {wait_for_rate_limit, bucket_key(Endpoint)})
    end.

-spec update_rate_limit(string(), [{string(), string()}]) -> ok.
update_rate_limit(Endpoint, Headers) ->
    case config:get_value(rate_limit_enabled, true) of
        false -> ok;
        true -> gen_server:cast(?MODULE, {update_rate_limit, bucket_key(Endpoint), Headers})
    end.

-spec is_rate_limited(string()) -> boolean().
is_rate_limited(Endpoint) ->
    gen_server:call(?MODULE, {is_rate_limited, bucket_key(Endpoint)}).

-spec get_bucket_info(string()) -> {ok, map()} | {error, not_found}.
get_bucket_info(Endpoint) ->
    gen_server:call(?MODULE, {get_bucket_info, bucket_key(Endpoint)}).

%% ==========================================================
%% gen_server callbacks
%% ==========================================================

init([]) ->
    ets:new(?BUCKET_TABLE, [named_table, public, set, {keypos, 1}]),
    erlang:send_after(?CLEANUP_INTERVAL, self(), cleanup_expired),
    {ok, #state{}}.

handle_call({wait_for_rate_limit, BucketKey}, _From, State) ->
    Result = check_rate_limit(BucketKey),
    {reply, Result, State};

handle_call({is_rate_limited, BucketKey}, _From, State) ->
    Result = case check_rate_limit(BucketKey) of
        ok -> false;
        {wait, _} -> true
    end,
    {reply, Result, State};

handle_call({get_bucket_info, BucketKey}, _From, State) ->
    Result = case ets:lookup(?BUCKET_TABLE, BucketKey) of
        [] -> {error, not_found};
        [{_, Bucket}] ->
            {ok, #{
                remaining => Bucket#bucket.remaining,
                reset_at => Bucket#bucket.reset_at,
                limit => Bucket#bucket.limit,
                global => Bucket#bucket.global
            }}
    end,
    {reply, Result, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({update_rate_limit, BucketKey, Headers}, State) ->
    update_bucket_from_headers(BucketKey, Headers),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(cleanup_expired, State) ->
    cleanup_expired_buckets(),
    erlang:send_after(?CLEANUP_INTERVAL, self(), cleanup_expired),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ets:delete(?BUCKET_TABLE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ==========================================================
%% Internal Functions
%% ==========================================================

-spec bucket_key(string()) -> string().
bucket_key(Endpoint) ->
    %% Extract route pattern (replace IDs with placeholders for bucket grouping)
    %% e.g., "/channels/123/messages" -> "/channels/:id/messages"
    Parts = string:tokens(Endpoint, "/"),
    NormalizedParts = [normalize_part(P) || P <- Parts],
    string:join(NormalizedParts, "/").

-spec normalize_part(string()) -> string().
normalize_part(Part) ->
    case is_snowflake(Part) of
        true -> ":id";
        false -> Part
    end.

-spec is_snowflake(string()) -> boolean().
is_snowflake(Part) ->
    %% Discord snowflakes are 17-19 digit numbers
    case catch list_to_integer(Part) of
        N when is_integer(N), N > 0 ->
            Length = length(Part),
            Length >= 17 andalso Length =< 19;
        _ -> false
    end.

-spec check_rate_limit(string()) -> ok | {wait, non_neg_integer()}.
check_rate_limit(BucketKey) ->
    Now = erlang:system_time(millisecond),
    %% Check global rate limit first
    GlobalResult = case ets:lookup(?BUCKET_TABLE, ?GLOBAL_KEY) of
        [] -> ok;
        [{_, GlobalBucket}] ->
            check_bucket(GlobalBucket, Now)
    end,
    case GlobalResult of
        {wait, GlobalWait} -> {wait, GlobalWait};
        ok ->
            %% Check endpoint-specific bucket
            case ets:lookup(?BUCKET_TABLE, BucketKey) of
                [] -> ok;
                [{_, Bucket}] -> check_bucket(Bucket, Now)
            end
    end.

-spec check_bucket(#bucket{}, non_neg_integer()) -> ok | {wait, non_neg_integer()}.
check_bucket(#bucket{remaining = Remaining, reset_at = ResetAt}, Now) when Remaining =< 0 ->
    if
        ResetAt > Now -> {wait, ResetAt - Now};
        true -> ok
    end;
check_bucket(_, _) ->
    ok.

-spec update_bucket_from_headers(string(), [{string(), string()}]) -> ok.
update_bucket_from_headers(BucketKey, Headers) ->
    HeaderMap = maps:from_list([{string:to_lower(K), V} || {K, V} <- Headers]),

    %% Check for global rate limit
    IsGlobal = maps:get("x-ratelimit-global", HeaderMap, "false") =:= "true",

    %% Parse rate limit headers
    Remaining = parse_int_header(HeaderMap, "x-ratelimit-remaining", 1),
    Limit = parse_int_header(HeaderMap, "x-ratelimit-limit", 1),
    ResetAfter = parse_float_header(HeaderMap, "x-ratelimit-reset-after", 0.0),

    %% Handle Retry-After header (used in 429 responses)
    RetryAfter = parse_float_header(HeaderMap, "retry-after", 0.0),

    Now = erlang:system_time(millisecond),
    WaitMs = max(round(ResetAfter * 1000), round(RetryAfter * 1000)),
    ResetAt = Now + WaitMs,

    Bucket = #bucket{
        remaining = Remaining,
        reset_at = ResetAt,
        limit = Limit,
        global = IsGlobal
    },

    Key = case IsGlobal of
        true -> ?GLOBAL_KEY;
        false -> BucketKey
    end,

    ets:insert(?BUCKET_TABLE, {Key, Bucket}),
    ?DEBUG("Updated rate limit bucket ~p: remaining=~p, reset_at=~p", [Key, Remaining, ResetAt]),
    ok.

-spec parse_int_header(map(), string(), integer()) -> integer().
parse_int_header(Headers, Key, Default) ->
    case maps:get(Key, Headers, undefined) of
        undefined -> Default;
        Value ->
            case catch list_to_integer(Value) of
                N when is_integer(N) -> N;
                _ -> Default
            end
    end.

-spec parse_float_header(map(), string(), float()) -> float().
parse_float_header(Headers, Key, Default) ->
    case maps:get(Key, Headers, undefined) of
        undefined -> Default;
        Value ->
            case catch list_to_float(Value) of
                F when is_float(F) -> F;
                _ ->
                    case catch list_to_integer(Value) of
                        I when is_integer(I) -> float(I);
                        _ -> Default
                    end
            end
    end.

-spec cleanup_expired_buckets() -> ok.
cleanup_expired_buckets() ->
    Now = erlang:system_time(millisecond),
    %% Delete all buckets where reset_at has passed and remaining is above 0
    %% (which means they're no longer relevant)
    ets:foldl(
        fun({Key, #bucket{reset_at = ResetAt}}, _Acc) ->
            if
                ResetAt < Now -> ets:delete(?BUCKET_TABLE, Key);
                true -> ok
            end
        end,
        ok,
        ?BUCKET_TABLE
    ),
    ok.
