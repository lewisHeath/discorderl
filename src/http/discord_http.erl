-module(discord_http).
-export([request/3, request/4, request/5]).
-export_type([result/0, method/0, endpoint/0]).

-include("macros.hrl").
-include("logging.hrl").
-define(BASE_URL, "https://discord.com/api/v10").
-define(JSON_OPTS, [return_maps]).

%% Types
-type method() :: get | post | put | delete | patch.
-type endpoint() :: string() | [string() | binary() | atom() | integer()].
-type headers() :: [{string(), string()}].
-type body() :: map().
-type result() :: {ok, term()} | {error, term()}.
-type request_opts() :: #{
    retries => non_neg_integer(),
    timeout => non_neg_integer()
}.

%% ==========================================================
%% Public API
%% ==========================================================
-spec request(method(), endpoint(), body()) -> result().
request(Method, Endpoint, Body) ->
    request(Method, Endpoint, [], Body).

-spec request(method(), endpoint(), headers(), body()) -> result().
request(Method, Endpoint, Headers, Body) ->
    request(Method, Endpoint, Headers, Body, #{}).

-spec request(method(), endpoint(), headers(), body(), request_opts()) -> result().
request(Method, Endpoint, Headers, Body, Opts) ->
    MaxRetries = maps:get(retries, Opts, config:get_value(http_retries, 3)),
    Timeout = maps:get(timeout, Opts, config:get_value(http_timeout, 30000)),
    EndpointStr = flatten_endpoint(Endpoint),
    do_request(Method, EndpointStr, Headers, Body, Timeout, MaxRetries, 0).

-spec do_request(method(), string(), headers(), body(), non_neg_integer(), non_neg_integer(), non_neg_integer()) -> result().
do_request(_Method, _Endpoint, _Headers, _Body, _Timeout, MaxRetries, Attempt) when Attempt >= MaxRetries ->
    {error, {rate_limited, max_retries_exceeded}};
do_request(Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt) ->
    %% Wait for rate limit if needed
    case rate_limiter:wait_for_rate_limit(Endpoint) of
        {wait, WaitMs} ->
            ?DEBUG("Rate limited for ~s, waiting ~p ms", [Endpoint, WaitMs]),
            timer:sleep(WaitMs),
            do_request(Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt);
        ok ->
            execute_request(Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt)
    end.

-spec execute_request(method(), string(), headers(), body(), non_neg_integer(), non_neg_integer(), non_neg_integer()) -> result().
execute_request(Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt) ->
    URL = build_url(Endpoint),
    FullHeaders = default_headers() ++ Headers,
    HttpOpts = [{timeout, Timeout}],
    ReqOpts = [{body_format, binary}, {full_result, true}],

    Result = case Method of
        get ->
            httpc:request(Method, {URL, FullHeaders}, HttpOpts, ReqOpts);
        _ ->
            JsonBody = jsx:encode(Body),
            ?DEBUG("Requesting ~s with method ~p and body: ~p", [URL, Method, JsonBody]),
            httpc:request(Method, {URL, FullHeaders, "application/json", JsonBody}, HttpOpts, ReqOpts)
    end,

    case Result of
        {ok, {{_, StatusCode, _}, RespHeaders, RespBody}} ->
            %% Update rate limiter with response headers
            rate_limiter:update_rate_limit(Endpoint, RespHeaders),
            handle_response(StatusCode, RespBody, Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt);
        Error ->
            {error, Error}
    end.

-spec handle_response(integer(), binary(), method(), string(), headers(), body(), non_neg_integer(), non_neg_integer(), non_neg_integer()) -> result().
handle_response(200, RespBody, _Method, _Endpoint, _Headers, _Body, _Timeout, _MaxRetries, _Attempt) ->
    decode_ok(RespBody);
handle_response(201, RespBody, _Method, _Endpoint, _Headers, _Body, _Timeout, _MaxRetries, _Attempt) ->
    decode_ok(RespBody);
handle_response(204, _, _Method, _Endpoint, _Headers, _Body, _Timeout, _MaxRetries, _Attempt) ->
    {ok, ok};
handle_response(429, RespBody, Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt) ->
    %% Rate limited - retry after wait
    Decoded = jsx:decode(RespBody, ?JSON_OPTS),
    RetryAfter = maps:get(<<"retry_after">>, Decoded, 1.0),
    WaitMs = round(RetryAfter * 1000),
    ?DEBUG("Rate limited (429), waiting ~p ms before retry", [WaitMs]),
    timer:sleep(WaitMs),
    do_request(Method, Endpoint, Headers, Body, Timeout, MaxRetries, Attempt + 1);
handle_response(Code, RespBody, _Method, _Endpoint, _Headers, _Body, _Timeout, _MaxRetries, _Attempt) ->
    decode_error(Code, RespBody).


%% ==========================================================
%% Internal Functions
%% ==========================================================
-spec flatten_endpoint(endpoint()) -> string().
flatten_endpoint(Endpoint) when is_list(Endpoint) ->
    case io_lib:char_list(Endpoint) of
        true -> Endpoint;
        false -> lists:flatten(to_iodata(Endpoint))
    end;
flatten_endpoint(Endpoint) when is_binary(Endpoint) ->
    binary_to_list(Endpoint).

-spec build_url(string()) -> string().
build_url(Endpoint) -> ?BASE_URL ++ Endpoint.

-spec default_headers() -> headers().
default_headers() ->
    [
        {"User-Agent", "DiscordBot (Erlang)"},
        {"Content-Type", "application/json"},
        {"Accept", "application/json"},
        {"Authorization", "Bot " ++ ?BOT_TOKEN}
    ].

to_iodata(Endpoint) when is_list(Endpoint) ->
    lists:map(fun
        (E) when is_binary(E) -> E;
        (E) when is_atom(E) -> atom_to_list(E);
        (E) when is_integer(E) -> integer_to_list(E);
        (E) when is_float(E) -> float_to_list(E);
        (E) when is_tuple(E) -> tuple_to_list(E);
        (E) when is_list(E) -> E
    end, Endpoint).

-spec decode_ok(binary()) -> result().
decode_ok(Body) ->
    {ok, jsx:decode(Body, ?JSON_OPTS)}.


-spec decode_error(integer(), binary()) -> result().
decode_error(Code, Body) ->
    {error, {http_error, Code, jsx:decode(Body, ?JSON_OPTS)}}.
