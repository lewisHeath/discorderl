-module(discord).

-include("discord_interaction.hrl").

%% Interaction responses
-export([
    reply/2,
    reply/3,
    reply_ephemeral/2,
    defer/1,
    defer_ephemeral/1,
    followup/2,
    followup/3,
    edit_response/2,
    delete_response/1
]).

%% Messages
-export([
    send_message/2,
    send_message/3,
    edit_message/3,
    delete_message/2
]).

%% Embed builder (fluent API)
-export([
    embed/0,
    embed_title/2,
    embed_description/2,
    embed_url/2,
    embed_color/2,
    embed_timestamp/2,
    embed_footer/2,
    embed_footer/3,
    embed_image/2,
    embed_thumbnail/2,
    embed_author/2,
    embed_author/3,
    embed_author/4,
    embed_field/3,
    embed_field/4
]).

%% Components
-export([
    action_row/1,
    button/3,
    button_link/2,
    button_disabled/3,
    select_menu/3,
    text_input/3,
    text_input/4
]).

%% Response types
-define(PONG, 1).
-define(CHANNEL_MESSAGE_WITH_SOURCE, 4).
-define(DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE, 5).
-define(DEFERRED_UPDATE_MESSAGE, 6).
-define(UPDATE_MESSAGE, 7).
-define(APPLICATION_COMMAND_AUTOCOMPLETE_RESULT, 8).
-define(MODAL, 9).

%% Button styles
-define(BUTTON_PRIMARY, 1).
-define(BUTTON_SECONDARY, 2).
-define(BUTTON_SUCCESS, 3).
-define(BUTTON_DANGER, 4).
-define(BUTTON_LINK, 5).

%% ==========================================================
%% Interaction Responses
%% ==========================================================

%% Reply to an interaction with a text message
-spec reply(#interaction{}, binary()) -> discord_http:result().
reply(Interaction, Content) when is_binary(Content) ->
    reply(Interaction, Content, #{}).

-spec reply(#interaction{}, binary(), map()) -> discord_http:result().
reply(Interaction, Content, Opts) when is_binary(Content) ->
    Flags = maps:get(flags, Opts, 0),
    Embeds = maps:get(embeds, Opts, []),
    Components = maps:get(components, Opts, []),

    Data = #{
        <<"content">> => Content,
        <<"flags">> => Flags,
        <<"embeds">> => Embeds,
        <<"components">> => Components
    },

    ResponseBody = #{
        <<"type">> => ?CHANNEL_MESSAGE_WITH_SOURCE,
        <<"data">> => maps:filter(fun(_, V) -> V =/= [] andalso V =/= 0 end, Data)
    },

    interaction_http:create_response(Interaction, ResponseBody).

%% Reply with an ephemeral message (only visible to the user)
-spec reply_ephemeral(#interaction{}, binary()) -> discord_http:result().
reply_ephemeral(Interaction, Content) when is_binary(Content) ->
    reply(Interaction, Content, #{flags => 64}).  %% 64 = ephemeral flag

%% Defer the response (show "thinking..." indicator)
-spec defer(#interaction{}) -> discord_http:result().
defer(Interaction) ->
    ResponseBody = #{
        <<"type">> => ?DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE
    },
    interaction_http:create_response(Interaction, ResponseBody).

%% Defer with ephemeral flag
-spec defer_ephemeral(#interaction{}) -> discord_http:result().
defer_ephemeral(Interaction) ->
    ResponseBody = #{
        <<"type">> => ?DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE,
        <<"data">> => #{<<"flags">> => 64}
    },
    interaction_http:create_response(Interaction, ResponseBody).

%% Send a followup message
-spec followup(#interaction{}, binary()) -> discord_http:result().
followup(Interaction, Content) when is_binary(Content) ->
    followup(Interaction, Content, #{}).

-spec followup(#interaction{}, binary(), map()) -> discord_http:result().
followup(Interaction, Content, Opts) when is_binary(Content) ->
    Flags = maps:get(flags, Opts, 0),
    Embeds = maps:get(embeds, Opts, []),
    Components = maps:get(components, Opts, []),

    Body = #{
        <<"content">> => Content,
        <<"flags">> => Flags,
        <<"embeds">> => Embeds,
        <<"components">> => Components
    },

    FilteredBody = maps:filter(fun(_, V) -> V =/= [] andalso V =/= 0 end, Body),
    interaction_http:create_followup(Interaction, FilteredBody).

%% Edit the original response
-spec edit_response(#interaction{}, binary() | map()) -> discord_http:result().
edit_response(Interaction, Content) when is_binary(Content) ->
    interaction_http:edit_original_response(Interaction, #{<<"content">> => Content});
edit_response(Interaction, Data) when is_map(Data) ->
    interaction_http:edit_original_response(Interaction, Data).

%% Delete the original response
-spec delete_response(#interaction{}) -> discord_http:result().
delete_response(Interaction) ->
    interaction_http:delete_original_response(Interaction).

%% ==========================================================
%% Messages
%% ==========================================================

%% Send a message to a channel
-spec send_message(binary(), binary()) -> discord_http:result().
send_message(ChannelId, Content) when is_binary(Content) ->
    send_message(ChannelId, Content, #{}).

-spec send_message(binary(), binary(), map()) -> discord_http:result().
send_message(ChannelId, Content, Opts) when is_binary(Content) ->
    Embeds = maps:get(embeds, Opts, []),
    Components = maps:get(components, Opts, []),

    Data = #{
        <<"content">> => Content,
        <<"embeds">> => Embeds,
        <<"components">> => Components
    },

    FilteredData = maps:filter(fun(_, V) -> V =/= [] end, Data),
    messages_http:create_message(ChannelId, FilteredData).

%% Edit a message
-spec edit_message(binary(), binary(), binary() | map()) -> discord_http:result().
edit_message(ChannelId, MessageId, Content) when is_binary(Content) ->
    messages_http:edit_message(ChannelId, MessageId, #{<<"content">> => Content});
edit_message(ChannelId, MessageId, Data) when is_map(Data) ->
    messages_http:edit_message(ChannelId, MessageId, Data).

%% Delete a message
-spec delete_message(binary(), binary()) -> discord_http:result().
delete_message(ChannelId, MessageId) ->
    messages_http:delete_message(ChannelId, MessageId).

%% ==========================================================
%% Embed Builder (Fluent API)
%% ==========================================================

%% Create a new empty embed
-spec embed() -> map().
embed() ->
    #{}.

%% Set embed title
-spec embed_title(map(), binary()) -> map().
embed_title(Embed, Title) ->
    Embed#{<<"title">> => Title}.

%% Set embed description
-spec embed_description(map(), binary()) -> map().
embed_description(Embed, Description) ->
    Embed#{<<"description">> => Description}.

%% Set embed URL
-spec embed_url(map(), binary()) -> map().
embed_url(Embed, Url) ->
    Embed#{<<"url">> => Url}.

%% Set embed color (integer)
-spec embed_color(map(), integer()) -> map().
embed_color(Embed, Color) ->
    Embed#{<<"color">> => Color}.

%% Set embed timestamp (ISO8601 string)
-spec embed_timestamp(map(), binary()) -> map().
embed_timestamp(Embed, Timestamp) ->
    Embed#{<<"timestamp">> => Timestamp}.

%% Set embed footer (text only)
-spec embed_footer(map(), binary()) -> map().
embed_footer(Embed, Text) ->
    Embed#{<<"footer">> => #{<<"text">> => Text}}.

%% Set embed footer with icon
-spec embed_footer(map(), binary(), binary()) -> map().
embed_footer(Embed, Text, IconUrl) ->
    Embed#{<<"footer">> => #{<<"text">> => Text, <<"icon_url">> => IconUrl}}.

%% Set embed image
-spec embed_image(map(), binary()) -> map().
embed_image(Embed, Url) ->
    Embed#{<<"image">> => #{<<"url">> => Url}}.

%% Set embed thumbnail
-spec embed_thumbnail(map(), binary()) -> map().
embed_thumbnail(Embed, Url) ->
    Embed#{<<"thumbnail">> => #{<<"url">> => Url}}.

%% Set embed author (name only)
-spec embed_author(map(), binary()) -> map().
embed_author(Embed, Name) ->
    Embed#{<<"author">> => #{<<"name">> => Name}}.

%% Set embed author with URL
-spec embed_author(map(), binary(), binary()) -> map().
embed_author(Embed, Name, Url) ->
    Embed#{<<"author">> => #{<<"name">> => Name, <<"url">> => Url}}.

%% Set embed author with URL and icon
-spec embed_author(map(), binary(), binary(), binary()) -> map().
embed_author(Embed, Name, Url, IconUrl) ->
    Embed#{<<"author">> => #{<<"name">> => Name, <<"url">> => Url, <<"icon_url">> => IconUrl}}.

%% Add a field to embed (inline defaults to false)
-spec embed_field(map(), binary(), binary()) -> map().
embed_field(Embed, Name, Value) ->
    embed_field(Embed, Name, Value, false).

%% Add a field to embed with inline option
-spec embed_field(map(), binary(), binary(), boolean()) -> map().
embed_field(Embed, Name, Value, Inline) ->
    Field = #{<<"name">> => Name, <<"value">> => Value, <<"inline">> => Inline},
    ExistingFields = maps:get(<<"fields">>, Embed, []),
    Embed#{<<"fields">> => ExistingFields ++ [Field]}.

%% ==========================================================
%% Components
%% ==========================================================

%% Create an action row containing components
-spec action_row([map()]) -> map().
action_row(Components) ->
    #{
        <<"type">> => 1,  %% Action Row
        <<"components">> => Components
    }.

%% Create a button
%% Style: 1=Primary, 2=Secondary, 3=Success, 4=Danger
-spec button(binary(), binary(), integer()) -> map().
button(CustomId, Label, Style) ->
    #{
        <<"type">> => 2,  %% Button
        <<"style">> => Style,
        <<"label">> => Label,
        <<"custom_id">> => CustomId
    }.

%% Create a link button
-spec button_link(binary(), binary()) -> map().
button_link(Url, Label) ->
    #{
        <<"type">> => 2,  %% Button
        <<"style">> => ?BUTTON_LINK,
        <<"label">> => Label,
        <<"url">> => Url
    }.

%% Create a disabled button
-spec button_disabled(binary(), binary(), integer()) -> map().
button_disabled(CustomId, Label, Style) ->
    #{
        <<"type">> => 2,
        <<"style">> => Style,
        <<"label">> => Label,
        <<"custom_id">> => CustomId,
        <<"disabled">> => true
    }.

%% Create a select menu
-spec select_menu(binary(), [map()], binary()) -> map().
select_menu(CustomId, Options, Placeholder) ->
    #{
        <<"type">> => 3,  %% String Select
        <<"custom_id">> => CustomId,
        <<"options">> => Options,
        <<"placeholder">> => Placeholder
    }.

%% Create a text input (for modals)
-spec text_input(binary(), binary(), integer()) -> map().
text_input(CustomId, Label, Style) ->
    text_input(CustomId, Label, Style, #{}).

%% Create a text input with options
%% Style: 1=Short, 2=Paragraph
-spec text_input(binary(), binary(), integer(), map()) -> map().
text_input(CustomId, Label, Style, Opts) ->
    Base = #{
        <<"type">> => 4,  %% Text Input
        <<"custom_id">> => CustomId,
        <<"label">> => Label,
        <<"style">> => Style
    },
    maps:merge(Base, maps:with([<<"placeholder">>, <<"value">>, <<"required">>, <<"min_length">>, <<"max_length">>], Opts)).
