-module(discord_api_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Procs = [
        rate_limiter:get_spec(),
        discord_cache:get_spec(),
        discord_ws_conn:get_spec(),
        heartbeat:get_spec(),
        dispatcher:get_spec(),
        discord_events:get_spec()
    ],
    {ok, {{one_for_one, 1, 5}, Procs}}.
