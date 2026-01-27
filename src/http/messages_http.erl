-module(messages_http).

-export([
    %% Messages
    create_message/2,
    get_message/2,
    edit_message/3,
    delete_message/2,
    bulk_delete_messages/2,

    %% Reactions
    create_reaction/3,
    delete_own_reaction/3,
    delete_user_reaction/4,
    get_reactions/3,
    get_reactions/4,
    delete_all_reactions/2,
    delete_all_reactions_for_emoji/3,

    %% Pins
    pin_message/2,
    unpin_message/2,
    get_pinned_messages/1
]).

%% ==========================================================
%% Messages
%% ==========================================================

%% Create a new message in a channel
%% POST /channels/{channel.id}/messages
-spec create_message(binary(), map()) -> discord_http:result().
create_message(ChannelId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/messages"],
    discord_http:request(post, Endpoint, Data).

%% Get a specific message
%% GET /channels/{channel.id}/messages/{message.id}
-spec get_message(binary(), binary()) -> discord_http:result().
get_message(ChannelId, MessageId) ->
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId],
    discord_http:request(get, Endpoint, #{}).

%% Edit a message
%% PATCH /channels/{channel.id}/messages/{message.id}
-spec edit_message(binary(), binary(), map()) -> discord_http:result().
edit_message(ChannelId, MessageId, Data) ->
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId],
    discord_http:request(patch, Endpoint, Data).

%% Delete a message
%% DELETE /channels/{channel.id}/messages/{message.id}
-spec delete_message(binary(), binary()) -> discord_http:result().
delete_message(ChannelId, MessageId) ->
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId],
    discord_http:request(delete, Endpoint, #{}).

%% Bulk delete messages (2-100 messages, not older than 2 weeks)
%% POST /channels/{channel.id}/messages/bulk-delete
-spec bulk_delete_messages(binary(), [binary()]) -> discord_http:result().
bulk_delete_messages(ChannelId, MessageIds) when length(MessageIds) >= 2, length(MessageIds) =< 100 ->
    Endpoint = ["/channels/", ChannelId, "/messages/bulk-delete"],
    discord_http:request(post, Endpoint, #{<<"messages">> => MessageIds}).

%% ==========================================================
%% Reactions
%% ==========================================================

%% Create a reaction on a message
%% PUT /channels/{channel.id}/messages/{message.id}/reactions/{emoji}/@me
-spec create_reaction(binary(), binary(), binary()) -> discord_http:result().
create_reaction(ChannelId, MessageId, Emoji) ->
    EncodedEmoji = uri_string:quote(binary_to_list(Emoji)),
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions/", EncodedEmoji, "/@me"],
    discord_http:request(put, Endpoint, #{}).

%% Delete own reaction
%% DELETE /channels/{channel.id}/messages/{message.id}/reactions/{emoji}/@me
-spec delete_own_reaction(binary(), binary(), binary()) -> discord_http:result().
delete_own_reaction(ChannelId, MessageId, Emoji) ->
    EncodedEmoji = uri_string:quote(binary_to_list(Emoji)),
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions/", EncodedEmoji, "/@me"],
    discord_http:request(delete, Endpoint, #{}).

%% Delete a user's reaction
%% DELETE /channels/{channel.id}/messages/{message.id}/reactions/{emoji}/{user.id}
-spec delete_user_reaction(binary(), binary(), binary(), binary()) -> discord_http:result().
delete_user_reaction(ChannelId, MessageId, Emoji, UserId) ->
    EncodedEmoji = uri_string:quote(binary_to_list(Emoji)),
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions/", EncodedEmoji, "/", UserId],
    discord_http:request(delete, Endpoint, #{}).

%% Get users who reacted with a specific emoji
%% GET /channels/{channel.id}/messages/{message.id}/reactions/{emoji}
-spec get_reactions(binary(), binary(), binary()) -> discord_http:result().
get_reactions(ChannelId, MessageId, Emoji) ->
    get_reactions(ChannelId, MessageId, Emoji, #{}).

-spec get_reactions(binary(), binary(), binary(), map()) -> discord_http:result().
get_reactions(ChannelId, MessageId, Emoji, QueryParams) ->
    EncodedEmoji = uri_string:quote(binary_to_list(Emoji)),
    QueryString = build_query_string(QueryParams),
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions/", EncodedEmoji, QueryString],
    discord_http:request(get, Endpoint, #{}).

%% Delete all reactions on a message
%% DELETE /channels/{channel.id}/messages/{message.id}/reactions
-spec delete_all_reactions(binary(), binary()) -> discord_http:result().
delete_all_reactions(ChannelId, MessageId) ->
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions"],
    discord_http:request(delete, Endpoint, #{}).

%% Delete all reactions for a specific emoji
%% DELETE /channels/{channel.id}/messages/{message.id}/reactions/{emoji}
-spec delete_all_reactions_for_emoji(binary(), binary(), binary()) -> discord_http:result().
delete_all_reactions_for_emoji(ChannelId, MessageId, Emoji) ->
    EncodedEmoji = uri_string:quote(binary_to_list(Emoji)),
    Endpoint = ["/channels/", ChannelId, "/messages/", MessageId, "/reactions/", EncodedEmoji],
    discord_http:request(delete, Endpoint, #{}).

%% ==========================================================
%% Pins
%% ==========================================================

%% Pin a message in a channel
%% PUT /channels/{channel.id}/pins/{message.id}
-spec pin_message(binary(), binary()) -> discord_http:result().
pin_message(ChannelId, MessageId) ->
    Endpoint = ["/channels/", ChannelId, "/pins/", MessageId],
    discord_http:request(put, Endpoint, #{}).

%% Unpin a message
%% DELETE /channels/{channel.id}/pins/{message.id}
-spec unpin_message(binary(), binary()) -> discord_http:result().
unpin_message(ChannelId, MessageId) ->
    Endpoint = ["/channels/", ChannelId, "/pins/", MessageId],
    discord_http:request(delete, Endpoint, #{}).

%% Get all pinned messages in a channel
%% GET /channels/{channel.id}/pins
-spec get_pinned_messages(binary()) -> discord_http:result().
get_pinned_messages(ChannelId) ->
    Endpoint = ["/channels/", ChannelId, "/pins"],
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
