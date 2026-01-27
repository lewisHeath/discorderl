-module(commands_http).

-export([
    %% Global commands
    get_global_commands/0,
    create_global_command/1,
    get_global_command/1,
    edit_global_command/2,
    delete_global_command/1,
    bulk_overwrite_global_commands/1,

    %% Guild commands
    get_guild_commands/1,
    create_guild_command/2,
    get_guild_command/2,
    edit_guild_command/3,
    delete_guild_command/2,
    bulk_overwrite_guild_commands/2,

    %% Permissions
    get_guild_command_permissions/1,
    get_command_permissions/2,
    edit_command_permissions/3
]).

%% ==========================================================
%% Global Application Commands
%% ==========================================================

%% Get all global commands for the application
%% GET /applications/{application.id}/commands
-spec get_global_commands() -> discord_http:result().
get_global_commands() ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands"],
    discord_http:request(get, Endpoint, #{}).

%% Create a new global command
%% POST /applications/{application.id}/commands
-spec create_global_command(map()) -> discord_http:result().
create_global_command(CommandData) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands"],
    discord_http:request(post, Endpoint, CommandData).

%% Get a specific global command
%% GET /applications/{application.id}/commands/{command.id}
-spec get_global_command(binary()) -> discord_http:result().
get_global_command(CommandId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands/", CommandId],
    discord_http:request(get, Endpoint, #{}).

%% Edit a global command
%% PATCH /applications/{application.id}/commands/{command.id}
-spec edit_global_command(binary(), map()) -> discord_http:result().
edit_global_command(CommandId, CommandData) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands/", CommandId],
    discord_http:request(patch, Endpoint, CommandData).

%% Delete a global command
%% DELETE /applications/{application.id}/commands/{command.id}
-spec delete_global_command(binary()) -> discord_http:result().
delete_global_command(CommandId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands/", CommandId],
    discord_http:request(delete, Endpoint, #{}).

%% Bulk overwrite global commands
%% PUT /applications/{application.id}/commands
-spec bulk_overwrite_global_commands([map()]) -> discord_http:result().
bulk_overwrite_global_commands(Commands) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/commands"],
    discord_http:request(put, Endpoint, Commands).

%% ==========================================================
%% Guild Application Commands
%% ==========================================================

%% Get all commands for a specific guild
%% GET /applications/{application.id}/guilds/{guild.id}/commands
-spec get_guild_commands(binary()) -> discord_http:result().
get_guild_commands(GuildId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands"],
    discord_http:request(get, Endpoint, #{}).

%% Create a new guild command
%% POST /applications/{application.id}/guilds/{guild.id}/commands
-spec create_guild_command(binary(), map()) -> discord_http:result().
create_guild_command(GuildId, CommandData) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands"],
    discord_http:request(post, Endpoint, CommandData).

%% Get a specific guild command
%% GET /applications/{application.id}/guilds/{guild.id}/commands/{command.id}
-spec get_guild_command(binary(), binary()) -> discord_http:result().
get_guild_command(GuildId, CommandId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/", CommandId],
    discord_http:request(get, Endpoint, #{}).

%% Edit a guild command
%% PATCH /applications/{application.id}/guilds/{guild.id}/commands/{command.id}
-spec edit_guild_command(binary(), binary(), map()) -> discord_http:result().
edit_guild_command(GuildId, CommandId, CommandData) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/", CommandId],
    discord_http:request(patch, Endpoint, CommandData).

%% Delete a guild command
%% DELETE /applications/{application.id}/guilds/{guild.id}/commands/{command.id}
-spec delete_guild_command(binary(), binary()) -> discord_http:result().
delete_guild_command(GuildId, CommandId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/", CommandId],
    discord_http:request(delete, Endpoint, #{}).

%% Bulk overwrite guild commands
%% PUT /applications/{application.id}/guilds/{guild.id}/commands
-spec bulk_overwrite_guild_commands(binary(), [map()]) -> discord_http:result().
bulk_overwrite_guild_commands(GuildId, Commands) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands"],
    discord_http:request(put, Endpoint, Commands).

%% ==========================================================
%% Command Permissions
%% ==========================================================

%% Get permissions for all commands in a guild
%% GET /applications/{application.id}/guilds/{guild.id}/commands/permissions
-spec get_guild_command_permissions(binary()) -> discord_http:result().
get_guild_command_permissions(GuildId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/permissions"],
    discord_http:request(get, Endpoint, #{}).

%% Get permissions for a specific command
%% GET /applications/{application.id}/guilds/{guild.id}/commands/{command.id}/permissions
-spec get_command_permissions(binary(), binary()) -> discord_http:result().
get_command_permissions(GuildId, CommandId) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/", CommandId, "/permissions"],
    discord_http:request(get, Endpoint, #{}).

%% Edit permissions for a command
%% PUT /applications/{application.id}/guilds/{guild.id}/commands/{command.id}/permissions
-spec edit_command_permissions(binary(), binary(), map()) -> discord_http:result().
edit_command_permissions(GuildId, CommandId, Permissions) ->
    AppId = config:get_value(application_id),
    Endpoint = ["/applications/", AppId, "/guilds/", GuildId, "/commands/", CommandId, "/permissions"],
    discord_http:request(put, Endpoint, Permissions).
