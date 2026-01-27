-module(users_http).

-export([
    %% Users
    get_current_user/0,
    get_user/1,
    modify_current_user/1,

    %% DMs
    create_dm/1,
    get_current_user_guilds/0,
    get_current_user_guilds/1,

    %% Connections
    get_current_user_connections/0
]).

%% ==========================================================
%% Users
%% ==========================================================

%% Get the current user (bot)
%% GET /users/@me
-spec get_current_user() -> discord_http:result().
get_current_user() ->
    Endpoint = ["/users/@me"],
    discord_http:request(get, Endpoint, #{}).

%% Get a specific user
%% GET /users/{user.id}
-spec get_user(binary()) -> discord_http:result().
get_user(UserId) ->
    Endpoint = ["/users/", UserId],
    discord_http:request(get, Endpoint, #{}).

%% Modify the current user
%% PATCH /users/@me
-spec modify_current_user(map()) -> discord_http:result().
modify_current_user(Data) ->
    Endpoint = ["/users/@me"],
    discord_http:request(patch, Endpoint, Data).

%% ==========================================================
%% DMs
%% ==========================================================

%% Create a DM channel with a user
%% POST /users/@me/channels
-spec create_dm(binary()) -> discord_http:result().
create_dm(RecipientId) ->
    Endpoint = ["/users/@me/channels"],
    discord_http:request(post, Endpoint, #{<<"recipient_id">> => RecipientId}).

%% ==========================================================
%% Guilds
%% ==========================================================

%% Get guilds the current user is in
%% GET /users/@me/guilds
-spec get_current_user_guilds() -> discord_http:result().
get_current_user_guilds() ->
    get_current_user_guilds(#{}).

-spec get_current_user_guilds(map()) -> discord_http:result().
get_current_user_guilds(QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/users/@me/guilds", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% ==========================================================
%% Connections
%% ==========================================================

%% Get the current user's connections
%% GET /users/@me/connections
-spec get_current_user_connections() -> discord_http:result().
get_current_user_connections() ->
    Endpoint = ["/users/@me/connections"],
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
