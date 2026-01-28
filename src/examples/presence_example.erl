%% @doc Example: Bot presence and status
%%
%% This example shows how to set the bot's online status and activity.
%%
%% Usage:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Call any of these functions to update the bot's presence.
-module(presence_example).

-export([
    set_playing/1,
    set_watching/1,
    set_listening/1,
    set_streaming/2,
    set_competing/1,
    set_idle/0,
    set_dnd/0,
    set_invisible/0,
    set_online/0,
    rotating_status/0
]).

%% @doc Set the bot to "Playing <game>"
-spec set_playing(binary()) -> ok.
set_playing(GameName) ->
    discord:set_activity(playing, GameName),
    io:format("Status set to: Playing ~s~n", [GameName]).

%% @doc Set the bot to "Watching <thing>"
-spec set_watching(binary()) -> ok.
set_watching(Thing) ->
    discord:set_activity(watching, Thing),
    io:format("Status set to: Watching ~s~n", [Thing]).

%% @doc Set the bot to "Listening to <thing>"
-spec set_listening(binary()) -> ok.
set_listening(Thing) ->
    discord:set_activity(listening, Thing),
    io:format("Status set to: Listening to ~s~n", [Thing]).

%% @doc Set the bot to "Streaming <title>" with a Twitch URL
%% Note: Streaming status requires a valid Twitch or YouTube URL
-spec set_streaming(binary(), binary()) -> ok.
set_streaming(Title, Url) ->
    discord:set_activity(streaming, Title, #{
        <<"url">> => Url
    }),
    io:format("Status set to: Streaming ~s~n", [Title]).

%% @doc Set the bot to "Competing in <thing>"
-spec set_competing(binary()) -> ok.
set_competing(Thing) ->
    discord:set_activity(competing, Thing),
    io:format("Status set to: Competing in ~s~n", [Thing]).

%% @doc Set bot to idle (yellow/orange dot)
-spec set_idle() -> ok.
set_idle() ->
    discord:set_status(idle),
    io:format("Status set to: Idle~n").

%% @doc Set bot to Do Not Disturb (red dot)
-spec set_dnd() -> ok.
set_dnd() ->
    discord:set_status(dnd),
    io:format("Status set to: Do Not Disturb~n").

%% @doc Set bot to invisible (grey/offline dot)
-spec set_invisible() -> ok.
set_invisible() ->
    discord:set_status(invisible),
    io:format("Status set to: Invisible~n").

%% @doc Set bot to online (green dot)
-spec set_online() -> ok.
set_online() ->
    discord:set_status(online),
    io:format("Status set to: Online~n").

%% @doc Example: Rotate through different statuses every 30 seconds
%% Call this function to start rotating. It runs in a separate process.
-spec rotating_status() -> pid().
rotating_status() ->
    spawn(fun() -> rotate_loop(0) end).

rotate_loop(Index) ->
    Statuses = [
        fun() -> discord:set_activity(playing, <<"Erlang">>) end,
        fun() -> discord:set_activity(watching, <<"the logs">>) end,
        fun() -> discord:set_activity(listening, <<"/help">>) end,
        fun() -> discord:set_activity(competing, <<"uptime records">>) end
    ],

    %% Get current status function and execute it
    StatusFun = lists:nth((Index rem length(Statuses)) + 1, Statuses),
    StatusFun(),

    %% Wait 30 seconds then rotate
    timer:sleep(30000),
    rotate_loop(Index + 1).
