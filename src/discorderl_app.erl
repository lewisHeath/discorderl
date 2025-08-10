-module(discorderl_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    interactions_registry:start(),
    discord_api_sup:start_link().

stop(_State) ->
    interactions_registry:stop(),
    ok.
