-module(guilds_http).

-export([
    %% Guild
    get_guild/1,
    get_guild/2,
    modify_guild/2,

    %% Channels
    get_guild_channels/1,
    create_guild_channel/2,
    modify_guild_channel_positions/2,

    %% Members
    get_guild_member/2,
    list_guild_members/1,
    list_guild_members/2,
    search_guild_members/2,
    add_guild_member_role/3,
    remove_guild_member_role/3,
    modify_guild_member/3,
    modify_current_member/2,
    remove_guild_member/2,

    %% Roles
    get_guild_roles/1,
    create_guild_role/2,
    modify_guild_role_positions/2,
    modify_guild_role/3,
    delete_guild_role/2,

    %% Bans
    get_guild_bans/1,
    get_guild_bans/2,
    get_guild_ban/2,
    create_guild_ban/2,
    create_guild_ban/3,
    remove_guild_ban/2,

    %% Prune
    get_guild_prune_count/1,
    get_guild_prune_count/2,
    begin_guild_prune/1,
    begin_guild_prune/2,

    %% Misc
    get_guild_invites/1,
    get_guild_integrations/1,
    delete_guild_integration/2,
    get_guild_widget_settings/1,
    modify_guild_widget/2,
    get_guild_vanity_url/1
]).

%% ==========================================================
%% Guild
%% ==========================================================

%% Get a guild
%% GET /guilds/{guild.id}
-spec get_guild(binary()) -> discord_http:result().
get_guild(GuildId) ->
    get_guild(GuildId, #{}).

-spec get_guild(binary(), map()) -> discord_http:result().
get_guild(GuildId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/guilds/", GuildId, QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Modify a guild
%% PATCH /guilds/{guild.id}
-spec modify_guild(binary(), map()) -> discord_http:result().
modify_guild(GuildId, Data) ->
    Endpoint = ["/guilds/", GuildId],
    discord_http:request(patch, Endpoint, Data).

%% ==========================================================
%% Channels
%% ==========================================================

%% Get all channels in a guild
%% GET /guilds/{guild.id}/channels
-spec get_guild_channels(binary()) -> discord_http:result().
get_guild_channels(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/channels"],
    discord_http:request(get, Endpoint, #{}).

%% Create a channel in a guild
%% POST /guilds/{guild.id}/channels
-spec create_guild_channel(binary(), map()) -> discord_http:result().
create_guild_channel(GuildId, ChannelData) ->
    Endpoint = ["/guilds/", GuildId, "/channels"],
    discord_http:request(post, Endpoint, ChannelData).

%% Modify channel positions
%% PATCH /guilds/{guild.id}/channels
-spec modify_guild_channel_positions(binary(), [map()]) -> discord_http:result().
modify_guild_channel_positions(GuildId, Positions) ->
    Endpoint = ["/guilds/", GuildId, "/channels"],
    discord_http:request(patch, Endpoint, Positions).

%% ==========================================================
%% Members
%% ==========================================================

%% Get a guild member
%% GET /guilds/{guild.id}/members/{user.id}
-spec get_guild_member(binary(), binary()) -> discord_http:result().
get_guild_member(GuildId, UserId) ->
    Endpoint = ["/guilds/", GuildId, "/members/", UserId],
    discord_http:request(get, Endpoint, #{}).

%% List guild members
%% GET /guilds/{guild.id}/members
-spec list_guild_members(binary()) -> discord_http:result().
list_guild_members(GuildId) ->
    list_guild_members(GuildId, #{}).

-spec list_guild_members(binary(), map()) -> discord_http:result().
list_guild_members(GuildId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/guilds/", GuildId, "/members", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Search guild members by query
%% GET /guilds/{guild.id}/members/search
-spec search_guild_members(binary(), binary()) -> discord_http:result().
search_guild_members(GuildId, Query) ->
    QueryString = build_query_string(#{<<"query">> => Query}),
    Endpoint = ["/guilds/", GuildId, "/members/search", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Add a role to a guild member
%% PUT /guilds/{guild.id}/members/{user.id}/roles/{role.id}
-spec add_guild_member_role(binary(), binary(), binary()) -> discord_http:result().
add_guild_member_role(GuildId, UserId, RoleId) ->
    Endpoint = ["/guilds/", GuildId, "/members/", UserId, "/roles/", RoleId],
    discord_http:request(put, Endpoint, #{}).

%% Remove a role from a guild member
%% DELETE /guilds/{guild.id}/members/{user.id}/roles/{role.id}
-spec remove_guild_member_role(binary(), binary(), binary()) -> discord_http:result().
remove_guild_member_role(GuildId, UserId, RoleId) ->
    Endpoint = ["/guilds/", GuildId, "/members/", UserId, "/roles/", RoleId],
    discord_http:request(delete, Endpoint, #{}).

%% Modify a guild member
%% PATCH /guilds/{guild.id}/members/{user.id}
-spec modify_guild_member(binary(), binary(), map()) -> discord_http:result().
modify_guild_member(GuildId, UserId, Data) ->
    Endpoint = ["/guilds/", GuildId, "/members/", UserId],
    discord_http:request(patch, Endpoint, Data).

%% Modify current member's nickname
%% PATCH /guilds/{guild.id}/members/@me
-spec modify_current_member(binary(), map()) -> discord_http:result().
modify_current_member(GuildId, Data) ->
    Endpoint = ["/guilds/", GuildId, "/members/@me"],
    discord_http:request(patch, Endpoint, Data).

%% Remove (kick) a member from a guild
%% DELETE /guilds/{guild.id}/members/{user.id}
-spec remove_guild_member(binary(), binary()) -> discord_http:result().
remove_guild_member(GuildId, UserId) ->
    Endpoint = ["/guilds/", GuildId, "/members/", UserId],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Roles
%% ==========================================================

%% Get all roles in a guild
%% GET /guilds/{guild.id}/roles
-spec get_guild_roles(binary()) -> discord_http:result().
get_guild_roles(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/roles"],
    discord_http:request(get, Endpoint, #{}).

%% Create a role
%% POST /guilds/{guild.id}/roles
-spec create_guild_role(binary(), map()) -> discord_http:result().
create_guild_role(GuildId, RoleData) ->
    Endpoint = ["/guilds/", GuildId, "/roles"],
    discord_http:request(post, Endpoint, RoleData).

%% Modify role positions
%% PATCH /guilds/{guild.id}/roles
-spec modify_guild_role_positions(binary(), [map()]) -> discord_http:result().
modify_guild_role_positions(GuildId, Positions) ->
    Endpoint = ["/guilds/", GuildId, "/roles"],
    discord_http:request(patch, Endpoint, Positions).

%% Modify a role
%% PATCH /guilds/{guild.id}/roles/{role.id}
-spec modify_guild_role(binary(), binary(), map()) -> discord_http:result().
modify_guild_role(GuildId, RoleId, RoleData) ->
    Endpoint = ["/guilds/", GuildId, "/roles/", RoleId],
    discord_http:request(patch, Endpoint, RoleData).

%% Delete a role
%% DELETE /guilds/{guild.id}/roles/{role.id}
-spec delete_guild_role(binary(), binary()) -> discord_http:result().
delete_guild_role(GuildId, RoleId) ->
    Endpoint = ["/guilds/", GuildId, "/roles/", RoleId],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Bans
%% ==========================================================

%% Get all bans in a guild
%% GET /guilds/{guild.id}/bans
-spec get_guild_bans(binary()) -> discord_http:result().
get_guild_bans(GuildId) ->
    get_guild_bans(GuildId, #{}).

-spec get_guild_bans(binary(), map()) -> discord_http:result().
get_guild_bans(GuildId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/guilds/", GuildId, "/bans", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Get a specific ban
%% GET /guilds/{guild.id}/bans/{user.id}
-spec get_guild_ban(binary(), binary()) -> discord_http:result().
get_guild_ban(GuildId, UserId) ->
    Endpoint = ["/guilds/", GuildId, "/bans/", UserId],
    discord_http:request(get, Endpoint, #{}).

%% Create a ban
%% PUT /guilds/{guild.id}/bans/{user.id}
-spec create_guild_ban(binary(), binary()) -> discord_http:result().
create_guild_ban(GuildId, UserId) ->
    create_guild_ban(GuildId, UserId, #{}).

-spec create_guild_ban(binary(), binary(), map()) -> discord_http:result().
create_guild_ban(GuildId, UserId, Data) ->
    Endpoint = ["/guilds/", GuildId, "/bans/", UserId],
    discord_http:request(put, Endpoint, Data).

%% Remove a ban
%% DELETE /guilds/{guild.id}/bans/{user.id}
-spec remove_guild_ban(binary(), binary()) -> discord_http:result().
remove_guild_ban(GuildId, UserId) ->
    Endpoint = ["/guilds/", GuildId, "/bans/", UserId],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Prune
%% ==========================================================

%% Get prune count
%% GET /guilds/{guild.id}/prune
-spec get_guild_prune_count(binary()) -> discord_http:result().
get_guild_prune_count(GuildId) ->
    get_guild_prune_count(GuildId, #{}).

-spec get_guild_prune_count(binary(), map()) -> discord_http:result().
get_guild_prune_count(GuildId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/guilds/", GuildId, "/prune", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Begin prune
%% POST /guilds/{guild.id}/prune
-spec begin_guild_prune(binary()) -> discord_http:result().
begin_guild_prune(GuildId) ->
    begin_guild_prune(GuildId, #{}).

-spec begin_guild_prune(binary(), map()) -> discord_http:result().
begin_guild_prune(GuildId, Data) ->
    Endpoint = ["/guilds/", GuildId, "/prune"],
    discord_http:request(post, Endpoint, Data).

%% ==========================================================
%% Misc
%% ==========================================================

%% Get guild invites
%% GET /guilds/{guild.id}/invites
-spec get_guild_invites(binary()) -> discord_http:result().
get_guild_invites(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/invites"],
    discord_http:request(get, Endpoint, #{}).

%% Get guild integrations
%% GET /guilds/{guild.id}/integrations
-spec get_guild_integrations(binary()) -> discord_http:result().
get_guild_integrations(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/integrations"],
    discord_http:request(get, Endpoint, #{}).

%% Delete an integration
%% DELETE /guilds/{guild.id}/integrations/{integration.id}
-spec delete_guild_integration(binary(), binary()) -> discord_http:result().
delete_guild_integration(GuildId, IntegrationId) ->
    Endpoint = ["/guilds/", GuildId, "/integrations/", IntegrationId],
    discord_http:request(delete, Endpoint, #{}).

%% Get widget settings
%% GET /guilds/{guild.id}/widget
-spec get_guild_widget_settings(binary()) -> discord_http:result().
get_guild_widget_settings(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/widget"],
    discord_http:request(get, Endpoint, #{}).

%% Modify widget
%% PATCH /guilds/{guild.id}/widget
-spec modify_guild_widget(binary(), map()) -> discord_http:result().
modify_guild_widget(GuildId, Data) ->
    Endpoint = ["/guilds/", GuildId, "/widget"],
    discord_http:request(patch, Endpoint, Data).

%% Get vanity URL
%% GET /guilds/{guild.id}/vanity-url
-spec get_guild_vanity_url(binary()) -> discord_http:result().
get_guild_vanity_url(GuildId) ->
    Endpoint = ["/guilds/", GuildId, "/vanity-url"],
    discord_http:request(get, Endpoint, #{}).

%% ==========================================================
%% Internal Functions
%% ==========================================================

-spec build_query_string(map()) -> string().
build_query_string(Params) when map_size(Params) =:= 0 ->
    "";
build_query_string(Params) ->
    Pairs = maps:fold(
        fun(K, V, Acc) ->
            Key = to_string(K),
            Value = to_string(V),
            [Key ++ "=" ++ Value | Acc]
        end,
        [],
        Params
    ),
    "?" ++ string:join(Pairs, "&").

-spec to_string(term()) -> string().
to_string(V) when is_binary(V) -> binary_to_list(V);
to_string(V) when is_atom(V) -> atom_to_list(V);
to_string(V) when is_integer(V) -> integer_to_list(V);
to_string(V) when is_list(V) -> V.
