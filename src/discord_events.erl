-module(discord_events).
-behaviour(gen_server).

%% API.
-export([start_link/0]).

%% gen_server.
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    get_spec/0,
    register_function_handler/2,
    register_pid_handler/1,
    get_function_handlers/1,
    get_pid_handlers/0
]).

%% macros.
-include("logging.hrl").

-define(FUNCTION_HANDLERS_TABLE, discord_function_handlers).
-define(PID_HANDLERS_TABLE, discord_pid_handlers).

%% API.

get_spec() ->
    #{
        id => ?MODULE,
        start => {?MODULE, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        pids => [?MODULE]
    }.

-spec register_function_handler(EventType :: term() | all, Fun :: fun((map()) -> any())) -> ok.
register_function_handler(EventType, Fun) ->
    case erlang:is_function(Fun, 2) of
        true ->
            gen_server:cast(?MODULE, {register_function_handler, EventType, Fun});
        false ->
            error({invalid_function_handler, Fun})
    end.

-spec register_pid_handler(Pid :: pid()) -> ok.
register_pid_handler(Pid) ->
    case erlang:is_pid(Pid) of
        true ->
            gen_server:cast(?MODULE, {register_pid_handler, Pid});
        false ->
            error({invalid_pid_handler, Pid})
    end.

-spec get_pid_handlers() -> [pid()].
get_pid_handlers() ->
    gen_server:call(?MODULE, get_pid_handlers).

-spec get_function_handlers(EventType :: term()) -> [fun()].
get_function_handlers(EventType) ->
    gen_server:call(?MODULE, {get_function_handlers, EventType}).

-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% gen_server.

init([]) ->
    ets:new(?FUNCTION_HANDLERS_TABLE, [named_table, set, public]),
    ets:new(?PID_HANDLERS_TABLE, [named_table, set, public]),
    {ok, undefined}.

handle_call({get_function_handlers, EventType}, _From, State) ->
    Handlers = case ets:lookup(?FUNCTION_HANDLERS_TABLE, EventType) of
        [{EventType, EventHandlers}] -> EventHandlers;
        [] -> []
    end,
    ?DEBUG("Returning function handlers for event type ~p: ~p", [EventType, Handlers]),
    {reply, Handlers, State};
handle_call(get_pid_handlers, _From, State) ->
    Handlers = ets:tab2list(?PID_HANDLERS_TABLE),
    ?DEBUG("Returning registered pid_handlers: ~p", [Handlers]),
    {reply, Handlers, State};
handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast({register_function_handler, EventType, Fun}, State) ->
    ?DEBUG("Registering handler for event type ~p", [EventType]),
    case ets:lookup(?FUNCTION_HANDLERS_TABLE, EventType) of
        [{EventType, ExistingHandlers}] ->
            ets:insert(?FUNCTION_HANDLERS_TABLE, {EventType, [Fun | ExistingHandlers]});
        [] ->
            ets:insert(?FUNCTION_HANDLERS_TABLE, {EventType, [Fun]})
    end,
    {noreply, State};
handle_cast({register_pid_handler, Pid}, State) ->
    ?DEBUG("Registering pid handler for all events", []),
    ets:insert(?PID_HANDLERS_TABLE, {Pid}),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ets:delete(?FUNCTION_HANDLERS_TABLE),
    ets:delete(?PID_HANDLERS_TABLE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
