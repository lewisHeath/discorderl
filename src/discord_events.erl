-module(discord_events).
-behaviour(gen_server).

%% API
-export([start_link/0, child_spec/1, subscribe/1, subscribe/2, unsubscribe/1, unsubscribe/2, publish/2]).

%% gen_server callbacks
-export([init/1, handle_cast/2, handle_call/3, handle_info/2, terminate/2, code_change/3]).

-define(PID_TABLE, discord_events_pid).
-define(ALL_EVENTS, all).

%%%===================================================================
%%% API
%%%===================================================================

-spec start_link() -> {ok, pid()} | {error, any()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec child_spec(Args :: term()) -> map().
child_spec(_Args) ->
    #{id => ?MODULE,
      start => {?MODULE, start_link, []},
      restart => permanent,
      shutdown => 5000,
      type => worker}.

-spec subscribe(EventType :: term()) -> ok.
subscribe(EventType) ->
    subscribe(EventType, self()).

-spec subscribe(EventType :: term(), Pid :: pid()) -> ok.
subscribe(EventType, Pid) when is_pid(Pid) ->
    gen_server:cast(?MODULE, {subscribe, EventType, Pid}).

-spec unsubscribe(EventType :: term()) -> ok.
unsubscribe(EventType) ->
    unsubscribe(EventType, self()).

-spec unsubscribe(EventType :: term(), Pid :: pid()) -> ok.
unsubscribe(EventType, Pid) when is_pid(Pid) ->
    gen_server:cast(?MODULE, {unsubscribe, EventType, Pid}).

-spec publish(EventType :: term(), EventData :: map()) -> ok.
publish(EventType, EventData) ->
    gen_server:cast(?MODULE, {publish, EventType, EventData}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?PID_TABLE, [named_table, public, bag]),
    {ok, #{}}.

handle_cast({subscribe, EventType, Pid}, State) ->
    ets:insert(?PID_TABLE, {EventType, Pid}),
    {noreply, State};

handle_cast({unsubscribe, EventType, Pid}, State) ->
    ets:delete_object(?PID_TABLE, {EventType, Pid}),
    {noreply, State};

handle_cast({publish, EventType, EventData}, State) ->
    % Lookup subscribers for EventType and wildcard 'all'
    PidSubs = ets:lookup(?PID_TABLE, EventType) ++ ets:lookup(?PID_TABLE, ?ALL_EVENTS),

    % Send message to all subscribed pids
    lists:foreach(fun({_, Pid}) ->
                          Pid ! {discord_event, EventType, EventData}
                  end, PidSubs),

    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
