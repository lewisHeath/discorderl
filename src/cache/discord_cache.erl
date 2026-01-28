-module(discord_cache).
-behaviour(gen_server).

%% API
-export([
    start_link/0,
    get_spec/0,
    %% Guilds
    get_guild/1,
    put_guild/2,
    delete_guild/1,
    get_all_guilds/0,
    %% Channels
    get_channel/1,
    put_channel/2,
    delete_channel/1,
    get_guild_channels/1,
    %% Users
    get_user/1,
    put_user/2,
    delete_user/1,
    %% Members
    get_member/2,
    put_member/3,
    delete_member/2,
    get_guild_members/1,
    %% Roles
    get_role/2,
    put_role/3,
    delete_role/2,
    get_guild_roles/1,
    %% Utility
    clear_all/0,
    stats/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-include("logging.hrl").

-record(state, {}).

-define(GUILDS_TABLE, discord_cache_guilds).
-define(CHANNELS_TABLE, discord_cache_channels).
-define(USERS_TABLE, discord_cache_users).
-define(MEMBERS_TABLE, discord_cache_members).
-define(ROLES_TABLE, discord_cache_roles).

%% ==========================================================
%% API
%% ==========================================================

get_spec() ->
    #{
        id => ?MODULE,
        start => {?MODULE, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [?MODULE]
    }.

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% --- Guilds ---

-spec get_guild(binary()) -> {ok, map()} | {error, not_found}.
get_guild(GuildId) ->
    case ets:lookup(?GUILDS_TABLE, GuildId) of
        [{_, Guild}] -> {ok, Guild};
        [] -> {error, not_found}
    end.

-spec put_guild(binary(), map()) -> ok.
put_guild(GuildId, Guild) ->
    ets:insert(?GUILDS_TABLE, {GuildId, Guild}),
    ok.

-spec delete_guild(binary()) -> ok.
delete_guild(GuildId) ->
    ets:delete(?GUILDS_TABLE, GuildId),
    %% Also delete associated channels, members, roles
    ets:match_delete(?CHANNELS_TABLE, {'_', #{<<"guild_id">> => GuildId}}),
    ets:match_delete(?MEMBERS_TABLE, {{GuildId, '_'}, '_'}),
    ets:match_delete(?ROLES_TABLE, {{GuildId, '_'}, '_'}),
    ok.

-spec get_all_guilds() -> [map()].
get_all_guilds() ->
    [Guild || {_, Guild} <- ets:tab2list(?GUILDS_TABLE)].

%% --- Channels ---

-spec get_channel(binary()) -> {ok, map()} | {error, not_found}.
get_channel(ChannelId) ->
    case ets:lookup(?CHANNELS_TABLE, ChannelId) of
        [{_, Channel}] -> {ok, Channel};
        [] -> {error, not_found}
    end.

-spec put_channel(binary(), map()) -> ok.
put_channel(ChannelId, Channel) ->
    ets:insert(?CHANNELS_TABLE, {ChannelId, Channel}),
    ok.

-spec delete_channel(binary()) -> ok.
delete_channel(ChannelId) ->
    ets:delete(?CHANNELS_TABLE, ChannelId),
    ok.

-spec get_guild_channels(binary()) -> [map()].
get_guild_channels(GuildId) ->
    ets:foldl(
        fun({_, Channel}, Acc) ->
            case maps:get(<<"guild_id">>, Channel, undefined) of
                GuildId -> [Channel | Acc];
                _ -> Acc
            end
        end,
        [],
        ?CHANNELS_TABLE
    ).

%% --- Users ---

-spec get_user(binary()) -> {ok, map()} | {error, not_found}.
get_user(UserId) ->
    case ets:lookup(?USERS_TABLE, UserId) of
        [{_, User}] -> {ok, User};
        [] -> {error, not_found}
    end.

-spec put_user(binary(), map()) -> ok.
put_user(UserId, User) ->
    ets:insert(?USERS_TABLE, {UserId, User}),
    ok.

-spec delete_user(binary()) -> ok.
delete_user(UserId) ->
    ets:delete(?USERS_TABLE, UserId),
    ok.

%% --- Members (keyed by {GuildId, UserId}) ---

-spec get_member(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_member(GuildId, UserId) ->
    case ets:lookup(?MEMBERS_TABLE, {GuildId, UserId}) of
        [{_, Member}] -> {ok, Member};
        [] -> {error, not_found}
    end.

-spec put_member(binary(), binary(), map()) -> ok.
put_member(GuildId, UserId, Member) ->
    ets:insert(?MEMBERS_TABLE, {{GuildId, UserId}, Member}),
    ok.

-spec delete_member(binary(), binary()) -> ok.
delete_member(GuildId, UserId) ->
    ets:delete(?MEMBERS_TABLE, {GuildId, UserId}),
    ok.

-spec get_guild_members(binary()) -> [map()].
get_guild_members(GuildId) ->
    ets:foldl(
        fun({{G, _}, Member}, Acc) when G =:= GuildId -> [Member | Acc];
           (_, Acc) -> Acc
        end,
        [],
        ?MEMBERS_TABLE
    ).

%% --- Roles (keyed by {GuildId, RoleId}) ---

-spec get_role(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_role(GuildId, RoleId) ->
    case ets:lookup(?ROLES_TABLE, {GuildId, RoleId}) of
        [{_, Role}] -> {ok, Role};
        [] -> {error, not_found}
    end.

-spec put_role(binary(), binary(), map()) -> ok.
put_role(GuildId, RoleId, Role) ->
    ets:insert(?ROLES_TABLE, {{GuildId, RoleId}, Role}),
    ok.

-spec delete_role(binary(), binary()) -> ok.
delete_role(GuildId, RoleId) ->
    ets:delete(?ROLES_TABLE, {GuildId, RoleId}),
    ok.

-spec get_guild_roles(binary()) -> [map()].
get_guild_roles(GuildId) ->
    ets:foldl(
        fun({{G, _}, Role}, Acc) when G =:= GuildId -> [Role | Acc];
           (_, Acc) -> Acc
        end,
        [],
        ?ROLES_TABLE
    ).

%% --- Utility ---

-spec clear_all() -> ok.
clear_all() ->
    ets:delete_all_objects(?GUILDS_TABLE),
    ets:delete_all_objects(?CHANNELS_TABLE),
    ets:delete_all_objects(?USERS_TABLE),
    ets:delete_all_objects(?MEMBERS_TABLE),
    ets:delete_all_objects(?ROLES_TABLE),
    ok.

-spec stats() -> map().
stats() ->
    #{
        guilds => ets:info(?GUILDS_TABLE, size),
        channels => ets:info(?CHANNELS_TABLE, size),
        users => ets:info(?USERS_TABLE, size),
        members => ets:info(?MEMBERS_TABLE, size),
        roles => ets:info(?ROLES_TABLE, size)
    }.

%% ==========================================================
%% gen_server callbacks
%% ==========================================================

init([]) ->
    ets:new(?GUILDS_TABLE, [named_table, public, set]),
    ets:new(?CHANNELS_TABLE, [named_table, public, set]),
    ets:new(?USERS_TABLE, [named_table, public, set]),
    ets:new(?MEMBERS_TABLE, [named_table, public, set]),
    ets:new(?ROLES_TABLE, [named_table, public, set]),
    ?INFO("Discord cache started"),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ets:delete(?GUILDS_TABLE),
    ets:delete(?CHANNELS_TABLE),
    ets:delete(?USERS_TABLE),
    ets:delete(?MEMBERS_TABLE),
    ets:delete(?ROLES_TABLE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
