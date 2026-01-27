-module(channels_http).

-export([
    %% Channels
    get_channel/1,
    modify_channel/2,
    delete_channel/1,

    %% Messages
    get_channel_messages/1,
    get_channel_messages/2,

    %% Typing
    trigger_typing_indicator/1,

    %% Permissions
    edit_channel_permissions/3,
    delete_channel_permission/2,

    %% Invites
    get_channel_invites/1,
    create_channel_invite/1,
    create_channel_invite/2,

    %% Threads
    start_thread_with_message/3,
    start_thread_without_message/2,
    join_thread/1,
    leave_thread/1,
    add_thread_member/2,
    remove_thread_member/2,
    get_thread_member/2,
    list_thread_members/1,
    list_thread_members/2,
    list_public_archived_threads/1,
    list_public_archived_threads/2,
    list_private_archived_threads/1,
    list_private_archived_threads/2,
    list_joined_private_archived_threads/1,
    list_joined_private_archived_threads/2
]).

%% ==========================================================
%% Channels
%% ==========================================================

%% Get a channel by ID
%% GET /channels/{channel.id}
-spec get_channel(binary()) -> discord_http:result().
get_channel(ChannelId) ->
    Endpoint = ["/channels/", ChannelId],
    discord_http:request(get, Endpoint, #{}).

%% Modify a channel
%% PATCH /channels/{channel.id}
-spec modify_channel(binary(), map()) -> discord_http:result().
modify_channel(ChannelId, Data) ->
    Endpoint = ["/channels/", ChannelId],
    discord_http:request(patch, Endpoint, Data).

%% Delete a channel
%% DELETE /channels/{channel.id}
-spec delete_channel(binary()) -> discord_http:result().
delete_channel(ChannelId) ->
    Endpoint = ["/channels/", ChannelId],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Messages
%% ==========================================================

%% Get messages in a channel
%% GET /channels/{channel.id}/messages
-spec get_channel_messages(binary()) -> discord_http:result().
get_channel_messages(ChannelId) ->
    get_channel_messages(ChannelId, #{}).

-spec get_channel_messages(binary(), map()) -> discord_http:result().
get_channel_messages(ChannelId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/messages", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% ==========================================================
%% Typing
%% ==========================================================

%% Trigger typing indicator
%% POST /channels/{channel.id}/typing
-spec trigger_typing_indicator(binary()) -> discord_http:result().
trigger_typing_indicator(ChannelId) ->
    Endpoint = ["/channels/", ChannelId, "/typing"],
    discord_http:request(post, Endpoint, #{}).

%% ==========================================================
%% Permissions
%% ==========================================================

%% Edit channel permissions (for a role or user)
%% PUT /channels/{channel.id}/permissions/{overwrite.id}
-spec edit_channel_permissions(binary(), binary(), map()) -> discord_http:result().
edit_channel_permissions(ChannelId, OverwriteId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/permissions/", OverwriteId],
    discord_http:request(put, Endpoint, Data).

%% Delete channel permission overwrite
%% DELETE /channels/{channel.id}/permissions/{overwrite.id}
-spec delete_channel_permission(binary(), binary()) -> discord_http:result().
delete_channel_permission(ChannelId, OverwriteId) ->
    Endpoint = ["/channels/", ChannelId, "/permissions/", OverwriteId],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Invites
%% ==========================================================

%% Get channel invites
%% GET /channels/{channel.id}/invites
-spec get_channel_invites(binary()) -> discord_http:result().
get_channel_invites(ChannelId) ->
    Endpoint = ["/channels/", ChannelId, "/invites"],
    discord_http:request(get, Endpoint, #{}).

%% Create an invite
%% POST /channels/{channel.id}/invites
-spec create_channel_invite(binary()) -> discord_http:result().
create_channel_invite(ChannelId) ->
    create_channel_invite(ChannelId, #{}).

-spec create_channel_invite(binary(), map()) -> discord_http:result().
create_channel_invite(ChannelId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/invites"],
    discord_http:request(post, Endpoint, Data).

%% ==========================================================
%% Threads
%% ==========================================================

%% Start a thread from a message
%% POST /channels/{channel.id}/messages/{message.id}/threads
-spec start_thread_with_message(binary(), binary(), map()) -> discord_http:result().
start_thread_with_message(ChannelId, MessageId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/threads"],
    discord_http:request(post, Endpoint, Data).

%% Start a thread without a message
%% POST /channels/{channel.id}/threads
-spec start_thread_without_message(binary(), map()) -> discord_http:result().
start_thread_without_message(ChannelId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/threads"],
    discord_http:request(post, Endpoint, Data).

%% Join a thread
%% PUT /channels/{channel.id}/thread-members/@me
-spec join_thread(binary()) -> discord_http:result().
join_thread(ChannelId) ->
    Endpoint = ["/channels/", ChannelId, "/thread-members/@me"],
    discord_http:request(put, Endpoint, #{}).

%% Leave a thread
%% DELETE /channels/{channel.id}/thread-members/@me
-spec leave_thread(binary()) -> discord_http:result().
leave_thread(ChannelId) ->
    Endpoint = ["/channels/", ChannelId, "/thread-members/@me"],
    discord_http:request(delete, Endpoint, #{}).

%% Add a user to a thread
%% PUT /channels/{channel.id}/thread-members/{user.id}
-spec add_thread_member(binary(), binary()) -> discord_http:result().
add_thread_member(ChannelId, UserId) ->
    Endpoint = ["/channels/", ChannelId, "/thread-members/", UserId],
    discord_http:request(put, Endpoint, #{}).

%% Remove a user from a thread
%% DELETE /channels/{channel.id}/thread-members/{user.id}
-spec remove_thread_member(binary(), binary()) -> discord_http:result().
remove_thread_member(ChannelId, UserId) ->
    Endpoint = ["/channels/", ChannelId, "/thread-members/", UserId],
    discord_http:request(delete, Endpoint, #{}).

%% Get a thread member
%% GET /channels/{channel.id}/thread-members/{user.id}
-spec get_thread_member(binary(), binary()) -> discord_http:result().
get_thread_member(ChannelId, UserId) ->
    Endpoint = ["/channels/", ChannelId, "/thread-members/", UserId],
    discord_http:request(get, Endpoint, #{}).

%% List thread members
%% GET /channels/{channel.id}/thread-members
-spec list_thread_members(binary()) -> discord_http:result().
list_thread_members(ChannelId) ->
    list_thread_members(ChannelId, #{}).

-spec list_thread_members(binary(), map()) -> discord_http:result().
list_thread_members(ChannelId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/thread-members", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% List public archived threads
%% GET /channels/{channel.id}/threads/archived/public
-spec list_public_archived_threads(binary()) -> discord_http:result().
list_public_archived_threads(ChannelId) ->
    list_public_archived_threads(ChannelId, #{}).

-spec list_public_archived_threads(binary(), map()) -> discord_http:result().
list_public_archived_threads(ChannelId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/threads/archived/public", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% List private archived threads
%% GET /channels/{channel.id}/threads/archived/private
-spec list_private_archived_threads(binary()) -> discord_http:result().
list_private_archived_threads(ChannelId) ->
    list_private_archived_threads(ChannelId, #{}).

-spec list_private_archived_threads(binary(), map()) -> discord_http:result().
list_private_archived_threads(ChannelId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/threads/archived/private", QueryString],
    discord_http:request(get, Endpoint, #{}).

%% List joined private archived threads
%% GET /channels/{channel.id}/users/@me/threads/archived/private
-spec list_joined_private_archived_threads(binary()) -> discord_http:result().
list_joined_private_archived_threads(ChannelId) ->
    list_joined_private_archived_threads(ChannelId, #{}).

-spec list_joined_private_archived_threads(binary(), map()) -> discord_http:result().
list_joined_private_archived_threads(ChannelId, QueryParams) ->
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/users/@me/threads/archived/private", QueryString],
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
