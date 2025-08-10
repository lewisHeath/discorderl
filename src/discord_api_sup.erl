-module(discord_api_sup).
-behaviour(supervisor).

-export([
    start_link/0,
    init/1,
    child_spec/0
]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Procs = [
        discord_ws_conn:get_spec(),
        heartbeat:get_spec(),
        dispatcher:get_spec(),
        discord_events:child_spec([]),
        example_consumer:child_spec([])
    ],
    {ok, {{one_for_one, 60, 60}, Procs}}.

%% Use if starting this supervisor under your own supervision tree
child_spec() ->
    #{
        id => ?MODULE,
        start => {?MODULE, start_link, []},
        restart => permanent,
        type => supervisor,
        modules => [?MODULE]
    }.