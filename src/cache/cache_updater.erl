-module(cache_updater).

%% This module provides functions to update the cache from gateway events.
%% Call init/0 to register the event handlers.

-export([
    init/0,
    handle_event/2
]).

-include("logging.hrl").

%% ==========================================================
%% API
%% ==========================================================

%% Initialize cache updater by registering event handlers
-spec init() -> ok.
init() ->
    Events = [
        <<"GUILD_CREATE">>,
        <<"GUILD_UPDATE">>,
        <<"GUILD_DELETE">>,
        <<"CHANNEL_CREATE">>,
        <<"CHANNEL_UPDATE">>,
        <<"CHANNEL_DELETE">>,
        <<"GUILD_MEMBER_ADD">>,
        <<"GUILD_MEMBER_UPDATE">>,
        <<"GUILD_MEMBER_REMOVE">>,
        <<"GUILD_ROLE_CREATE">>,
        <<"GUILD_ROLE_UPDATE">>,
        <<"GUILD_ROLE_DELETE">>,
        <<"USER_UPDATE">>
    ],
    lists:foreach(fun(Event) ->
        discord_events:register_function_handler(Event, fun handle_event/2)
    end, Events),
    ?INFO("Cache updater initialized"),
    ok.

%% ==========================================================
%% Event Handlers
%% ==========================================================

-spec handle_event(map(), binary()) -> ok.

%% Guild events
handle_event(Data, <<"GUILD_CREATE">>) ->
    GuildId = maps:get(<<"id">>, Data),
    discord_cache:put_guild(GuildId, Data),
    %% Cache channels
    Channels = maps:get(<<"channels">>, Data, []),
    lists:foreach(fun(Channel) ->
        ChannelId = maps:get(<<"id">>, Channel),
        ChannelWithGuild = Channel#{<<"guild_id">> => GuildId},
        discord_cache:put_channel(ChannelId, ChannelWithGuild)
    end, Channels),
    %% Cache roles
    Roles = maps:get(<<"roles">>, Data, []),
    lists:foreach(fun(Role) ->
        RoleId = maps:get(<<"id">>, Role),
        discord_cache:put_role(GuildId, RoleId, Role)
    end, Roles),
    %% Cache members
    Members = maps:get(<<"members">>, Data, []),
    lists:foreach(fun(Member) ->
        case maps:get(<<"user">>, Member, undefined) of
            undefined -> ok;
            User ->
                UserId = maps:get(<<"id">>, User),
                discord_cache:put_user(UserId, User),
                discord_cache:put_member(GuildId, UserId, Member)
        end
    end, Members),
    ok;

handle_event(Data, <<"GUILD_UPDATE">>) ->
    GuildId = maps:get(<<"id">>, Data),
    discord_cache:put_guild(GuildId, Data),
    ok;

handle_event(Data, <<"GUILD_DELETE">>) ->
    GuildId = maps:get(<<"id">>, Data),
    discord_cache:delete_guild(GuildId),
    ok;

%% Channel events
handle_event(Data, <<"CHANNEL_CREATE">>) ->
    ChannelId = maps:get(<<"id">>, Data),
    discord_cache:put_channel(ChannelId, Data),
    ok;

handle_event(Data, <<"CHANNEL_UPDATE">>) ->
    ChannelId = maps:get(<<"id">>, Data),
    discord_cache:put_channel(ChannelId, Data),
    ok;

handle_event(Data, <<"CHANNEL_DELETE">>) ->
    ChannelId = maps:get(<<"id">>, Data),
    discord_cache:delete_channel(ChannelId),
    ok;

%% Member events
handle_event(Data, <<"GUILD_MEMBER_ADD">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    case maps:get(<<"user">>, Data, undefined) of
        undefined -> ok;
        User ->
            UserId = maps:get(<<"id">>, User),
            discord_cache:put_user(UserId, User),
            discord_cache:put_member(GuildId, UserId, Data)
    end,
    ok;

handle_event(Data, <<"GUILD_MEMBER_UPDATE">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    case maps:get(<<"user">>, Data, undefined) of
        undefined -> ok;
        User ->
            UserId = maps:get(<<"id">>, User),
            discord_cache:put_user(UserId, User),
            %% Merge with existing member data
            case discord_cache:get_member(GuildId, UserId) of
                {ok, Existing} ->
                    Updated = maps:merge(Existing, Data),
                    discord_cache:put_member(GuildId, UserId, Updated);
                {error, not_found} ->
                    discord_cache:put_member(GuildId, UserId, Data)
            end
    end,
    ok;

handle_event(Data, <<"GUILD_MEMBER_REMOVE">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    case maps:get(<<"user">>, Data, undefined) of
        undefined -> ok;
        User ->
            UserId = maps:get(<<"id">>, User),
            discord_cache:delete_member(GuildId, UserId)
    end,
    ok;

%% Role events
handle_event(Data, <<"GUILD_ROLE_CREATE">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    Role = maps:get(<<"role">>, Data),
    RoleId = maps:get(<<"id">>, Role),
    discord_cache:put_role(GuildId, RoleId, Role),
    ok;

handle_event(Data, <<"GUILD_ROLE_UPDATE">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    Role = maps:get(<<"role">>, Data),
    RoleId = maps:get(<<"id">>, Role),
    discord_cache:put_role(GuildId, RoleId, Role),
    ok;

handle_event(Data, <<"GUILD_ROLE_DELETE">>) ->
    GuildId = maps:get(<<"guild_id">>, Data),
    RoleId = maps:get(<<"role_id">>, Data),
    discord_cache:delete_role(GuildId, RoleId),
    ok;

%% User events
handle_event(Data, <<"USER_UPDATE">>) ->
    UserId = maps:get(<<"id">>, Data),
    discord_cache:put_user(UserId, Data),
    ok;

%% Fallback
handle_event(_Data, _Event) ->
    ok.
