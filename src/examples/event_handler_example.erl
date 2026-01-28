%% @doc Example: Handling Discord gateway events
%%
%% This example shows how to register handlers for various Discord events.
%%
%% Events are dispatched from the gateway websocket connection. Common events:
%% - MESSAGE_CREATE: Someone sent a message
%% - GUILD_MEMBER_ADD: Someone joined a guild
%% - GUILD_MEMBER_REMOVE: Someone left a guild
%% - PRESENCE_UPDATE: Someone's status changed
%% - READY: Bot successfully connected
%%
%% Usage:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register handlers: event_handler_example:setup().
%% 3. Events will be logged as they occur.
-module(event_handler_example).

-export([setup/0, setup/1]).

%% @doc Register all example event handlers
-spec setup() -> ok.
setup() ->
    setup([message_create, member_join, member_leave, presence]).

%% @doc Register specific event handlers
%% Options: message_create, member_join, member_leave, presence
-spec setup([atom()]) -> ok.
setup(Options) ->
    lists:foreach(fun(Opt) ->
        case Opt of
            message_create ->
                discord_events:register_handler('MESSAGE_CREATE', fun handle_message/1),
                io:format("Registered MESSAGE_CREATE handler~n");
            member_join ->
                discord_events:register_handler('GUILD_MEMBER_ADD', fun handle_member_join/1),
                io:format("Registered GUILD_MEMBER_ADD handler~n");
            member_leave ->
                discord_events:register_handler('GUILD_MEMBER_REMOVE', fun handle_member_leave/1),
                io:format("Registered GUILD_MEMBER_REMOVE handler~n");
            presence ->
                discord_events:register_handler('PRESENCE_UPDATE', fun handle_presence/1),
                io:format("Registered PRESENCE_UPDATE handler~n");
            _ ->
                io:format("Unknown option: ~p~n", [Opt])
        end
    end, Options),
    ok.

%% @doc Handle incoming messages
%% Note: Requires MESSAGE_CONTENT intent to see message content
handle_message(Data) ->
    Author = maps:get(<<"author">>, Data, #{}),
    Username = maps:get(<<"username">>, Author, <<"Unknown">>),
    Content = maps:get(<<"content">>, Data, <<"">>),
    ChannelId = maps:get(<<"channel_id">>, Data, <<"Unknown">>),

    %% Ignore bot messages to prevent loops
    IsBot = maps:get(<<"bot">>, Author, false),
    case IsBot of
        true ->
            ok;  %% Ignore bot messages
        false ->
            io:format("[MESSAGE] #~s | ~s: ~s~n", [ChannelId, Username, Content]),

            %% Example: Auto-respond to specific keywords
            case binary:match(string:lowercase(Content), <<"hello">>) of
                nomatch -> ok;
                _ ->
                    %% Uncomment to auto-reply:
                    %% discord:send_message(ChannelId, <<"Hello there!">>),
                    io:format("  ^ Someone said hello!~n")
            end
    end.

%% @doc Handle when someone joins a guild
handle_member_join(Data) ->
    GuildId = maps:get(<<"guild_id">>, Data, <<"Unknown">>),
    User = maps:get(<<"user">>, Data, #{}),
    Username = maps:get(<<"username">>, User, <<"Unknown">>),
    UserId = maps:get(<<"id">>, User, <<"Unknown">>),

    io:format("[JOIN] ~s (~s) joined guild ~s~n", [Username, UserId, GuildId]),

    %% Example: Send a welcome message
    %% You would need to know the welcome channel ID
    %% WelcomeChannelId = <<"your_channel_id">>,
    %% WelcomeMsg = <<"Welcome to the server, <@", UserId/binary, ">!">>,
    %% discord:send_message(WelcomeChannelId, WelcomeMsg),
    ok.

%% @doc Handle when someone leaves a guild
handle_member_leave(Data) ->
    GuildId = maps:get(<<"guild_id">>, Data, <<"Unknown">>),
    User = maps:get(<<"user">>, Data, #{}),
    Username = maps:get(<<"username">>, User, <<"Unknown">>),

    io:format("[LEAVE] ~s left guild ~s~n", [Username, GuildId]).

%% @doc Handle presence updates (status changes)
handle_presence(Data) ->
    User = maps:get(<<"user">>, Data, #{}),
    UserId = maps:get(<<"id">>, User, <<"Unknown">>),
    Status = maps:get(<<"status">>, Data, <<"unknown">>),

    %% Get activity if present
    Activities = maps:get(<<"activities">>, Data, []),
    Activity = case Activities of
        [A | _] ->
            Type = maps:get(<<"type">>, A, 0),
            Name = maps:get(<<"name">>, A, <<"">>),
            TypeStr = case Type of
                0 -> <<"Playing">>;
                1 -> <<"Streaming">>;
                2 -> <<"Listening to">>;
                3 -> <<"Watching">>;
                4 -> <<"Custom">>;
                5 -> <<"Competing in">>;
                _ -> <<"Doing">>
            end,
            <<TypeStr/binary, " ", Name/binary>>;
        [] ->
            <<"No activity">>
    end,

    io:format("[PRESENCE] User ~s is now ~s (~s)~n", [UserId, Status, Activity]).
