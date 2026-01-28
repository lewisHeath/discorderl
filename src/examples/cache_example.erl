%% @doc Example: Using the guild/channel/user cache
%%
%% This example shows how to access cached data from Discord.
%%
%% The cache is automatically populated when the bot connects and receives
%% GUILD_CREATE events. It's kept up-to-date as changes occur.
%%
%% Usage:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Wait for the bot to connect and receive guild data.
%% 3. Use any of these functions to query the cache.
-module(cache_example).

-export([
    show_guild_info/1,
    list_channels/1,
    find_channel_by_name/2,
    get_member_info/2,
    show_cache_stats/0
]).

%% @doc Display information about a guild
-spec show_guild_info(binary()) -> ok.
show_guild_info(GuildId) ->
    case discord:get_guild(GuildId) of
        {ok, Guild} ->
            Name = maps:get(<<"name">>, Guild, <<"Unknown">>),
            MemberCount = maps:get(<<"member_count">>, Guild, 0),
            io:format("Guild: ~s~n", [Name]),
            io:format("Member count: ~p~n", [MemberCount]),

            %% Show roles if available
            Roles = maps:get(<<"roles">>, Guild, []),
            io:format("Roles (~p):~n", [length(Roles)]),
            lists:foreach(fun(Role) ->
                RoleName = maps:get(<<"name">>, Role, <<"Unknown">>),
                io:format("  - ~s~n", [RoleName])
            end, lists:sublist(Roles, 10)),  %% Show first 10
            ok;
        {error, not_found} ->
            io:format("Guild ~s not found in cache~n", [GuildId]),
            io:format("The bot may not be in this guild, or it hasn't connected yet.~n")
    end.

%% @doc List all channels in a guild
-spec list_channels(binary()) -> ok.
list_channels(GuildId) ->
    case discord:get_guild_channels(GuildId) of
        {ok, Channels} ->
            io:format("Channels in guild (~p total):~n", [length(Channels)]),

            %% Group by type
            TextChannels = [C || C <- Channels, maps:get(<<"type">>, C, 0) =:= 0],
            VoiceChannels = [C || C <- Channels, maps:get(<<"type">>, C, 0) =:= 2],
            Categories = [C || C <- Channels, maps:get(<<"type">>, C, 0) =:= 4],

            io:format("~nCategories (~p):~n", [length(Categories)]),
            lists:foreach(fun(C) ->
                io:format("  📁 ~s~n", [maps:get(<<"name">>, C)])
            end, Categories),

            io:format("~nText Channels (~p):~n", [length(TextChannels)]),
            lists:foreach(fun(C) ->
                io:format("  #~s~n", [maps:get(<<"name">>, C)])
            end, TextChannels),

            io:format("~nVoice Channels (~p):~n", [length(VoiceChannels)]),
            lists:foreach(fun(C) ->
                io:format("  🔊 ~s~n", [maps:get(<<"name">>, C)])
            end, VoiceChannels),
            ok;
        {error, not_found} ->
            io:format("No channels found for guild ~s~n", [GuildId])
    end.

%% @doc Find a channel by name within a guild
-spec find_channel_by_name(binary(), binary()) -> {ok, map()} | not_found.
find_channel_by_name(GuildId, ChannelName) ->
    case discord:get_guild_channels(GuildId) of
        {ok, Channels} ->
            LowerName = string:lowercase(binary_to_list(ChannelName)),
            case lists:filter(fun(C) ->
                Name = maps:get(<<"name">>, C, <<"">>),
                string:lowercase(binary_to_list(Name)) =:= LowerName
            end, Channels) of
                [Channel | _] ->
                    Id = maps:get(<<"id">>, Channel),
                    Name = maps:get(<<"name">>, Channel),
                    io:format("Found channel: #~s (ID: ~s)~n", [Name, Id]),
                    {ok, Channel};
                [] ->
                    io:format("Channel '~s' not found~n", [ChannelName]),
                    not_found
            end;
        {error, not_found} ->
            io:format("Guild not found~n"),
            not_found
    end.

%% @doc Get information about a guild member
-spec get_member_info(binary(), binary()) -> ok.
get_member_info(GuildId, UserId) ->
    case discord:get_member(GuildId, UserId) of
        {ok, Member} ->
            Nick = maps:get(<<"nick">>, Member, undefined),
            JoinedAt = maps:get(<<"joined_at">>, Member, <<"Unknown">>),
            Roles = maps:get(<<"roles">>, Member, []),

            io:format("Member Info:~n"),
            case Nick of
                undefined -> io:format("  Nickname: (none)~n");
                _ -> io:format("  Nickname: ~s~n", [Nick])
            end,
            io:format("  Joined: ~s~n", [JoinedAt]),
            io:format("  Roles: ~p~n", [Roles]),
            ok;
        {error, not_found} ->
            io:format("Member ~s not found in guild ~s~n", [UserId, GuildId])
    end.

%% @doc Show cache statistics
-spec show_cache_stats() -> ok.
show_cache_stats() ->
    Stats = discord_cache:stats(),
    io:format("Cache Statistics:~n"),
    io:format("  Guilds:   ~p~n", [maps:get(guilds, Stats, 0)]),
    io:format("  Channels: ~p~n", [maps:get(channels, Stats, 0)]),
    io:format("  Users:    ~p~n", [maps:get(users, Stats, 0)]),
    io:format("  Members:  ~p~n", [maps:get(members, Stats, 0)]),
    io:format("  Roles:    ~p~n", [maps:get(roles, Stats, 0)]),
    ok.
