-module(discord).

-include("discord_interaction.hrl").
-include("presence.hrl").

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
    delete_response/1,
    update_message/2,
    show_modal/2,
    autocomplete/2
]).

%% Messages
-export([
    send_message/2,
    send_message/3,
    edit_message/3,
    delete_message/2
]).

%% Presence/Status
-export([
    set_status/1,
    set_activity/2,
    set_activity/3,
    set_presence/1
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
    button_emoji/4,
    select_menu/3,
    select_menu_option/2,
    select_menu_option/3,
    user_select/2,
    role_select/2,
    channel_select/2,
    mentionable_select/2,
    text_input/3,
    text_input/4
]).

%% Modals
-export([
    modal/2,
    modal/3
]).

%% Slash Command Builder
-export([
    command/2,
    command/3,
    command_option/2,
    command_option/3,
    command_choice/2,
    register_global_command/1,
    register_guild_command/2,
    sync_global_commands/1,
    sync_guild_commands/2
]).

%% Autocomplete
-export([
    autocomplete_choice/2
]).

%% Cache access
-export([
    get_guild/1,
    get_channel/1,
    get_user/1,
    get_member/2,
    get_role/2,
    cache_stats/0,
    init_cache/0
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

%% Update the message the component is attached to (for buttons/selects)
-spec update_message(#interaction{}, map()) -> discord_http:result().
update_message(Interaction, Data) ->
    ResponseBody = #{
        <<"type">> => ?UPDATE_MESSAGE,
        <<"data">> => Data
    },
    interaction_http:create_response(Interaction, ResponseBody).

%% Show a modal dialog
-spec show_modal(#interaction{}, map()) -> discord_http:result().
show_modal(Interaction, ModalData) ->
    ResponseBody = #{
        <<"type">> => ?MODAL,
        <<"data">> => ModalData
    },
    interaction_http:create_response(Interaction, ResponseBody).

%% Respond to autocomplete with choices
-spec autocomplete(#interaction{}, [map()]) -> discord_http:result().
autocomplete(Interaction, Choices) ->
    ResponseBody = #{
        <<"type">> => ?APPLICATION_COMMAND_AUTOCOMPLETE_RESULT,
        <<"data">> => #{<<"choices">> => Choices}
    },
    interaction_http:create_response(Interaction, ResponseBody).

%% ==========================================================
%% Presence/Status
%% ==========================================================

%% Set bot status: online | idle | dnd | invisible
-spec set_status(binary() | atom()) -> ok.
set_status(Status) when is_atom(Status) ->
    set_status(atom_to_binary(Status));
set_status(Status) when Status =:= <<"online">>;
                        Status =:= <<"idle">>;
                        Status =:= <<"dnd">>;
                        Status =:= <<"invisible">> ->
    presence:update_presence(#presence{status = Status}).

%% Set activity with type and name
%% Type: playing | streaming | listening | watching | competing (or 0-5)
-spec set_activity(atom() | integer(), binary()) -> ok.
set_activity(Type, Name) ->
    set_activity(Type, Name, #{}).

-spec set_activity(atom() | integer(), binary(), map()) -> ok.
set_activity(Type, Name, Opts) when is_atom(Type) ->
    TypeInt = activity_type_to_int(Type),
    set_activity(TypeInt, Name, Opts);
set_activity(Type, Name, Opts) when is_integer(Type) ->
    Activity = maps:merge(#{
        <<"type">> => Type,
        <<"name">> => Name
    }, Opts),
    Status = maps:get(status, Opts, <<"online">>),
    presence:update_presence(#presence{
        status = Status,
        activities = [Activity]
    }).

%% Full presence control
-spec set_presence(map()) -> ok.
set_presence(Opts) ->
    Status = maps:get(status, Opts, <<"online">>),
    Activities = maps:get(activities, Opts, []),
    Since = maps:get(since, Opts, null),
    Afk = maps:get(afk, Opts, false),
    presence:update_presence(#presence{
        since = Since,
        activities = Activities,
        status = Status,
        afk = Afk
    }).

activity_type_to_int(playing) -> 0;
activity_type_to_int(streaming) -> 1;
activity_type_to_int(listening) -> 2;
activity_type_to_int(watching) -> 3;
activity_type_to_int(custom) -> 4;
activity_type_to_int(competing) -> 5.

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

%% Create a button with emoji
-spec button_emoji(binary(), binary(), integer(), binary() | map()) -> map().
button_emoji(CustomId, Label, Style, Emoji) when is_binary(Emoji) ->
    (button(CustomId, Label, Style))#{<<"emoji">> => #{<<"name">> => Emoji}};
button_emoji(CustomId, Label, Style, Emoji) when is_map(Emoji) ->
    (button(CustomId, Label, Style))#{<<"emoji">> => Emoji}.

%% Create a select menu option
-spec select_menu_option(binary(), binary()) -> map().
select_menu_option(Label, Value) ->
    #{<<"label">> => Label, <<"value">> => Value}.

-spec select_menu_option(binary(), binary(), map()) -> map().
select_menu_option(Label, Value, Opts) ->
    Base = select_menu_option(Label, Value),
    maps:merge(Base, maps:with([<<"description">>, <<"emoji">>, <<"default">>], Opts)).

%% Create a user select menu
-spec user_select(binary(), binary()) -> map().
user_select(CustomId, Placeholder) ->
    #{
        <<"type">> => 5,  %% User Select
        <<"custom_id">> => CustomId,
        <<"placeholder">> => Placeholder
    }.

%% Create a role select menu
-spec role_select(binary(), binary()) -> map().
role_select(CustomId, Placeholder) ->
    #{
        <<"type">> => 6,  %% Role Select
        <<"custom_id">> => CustomId,
        <<"placeholder">> => Placeholder
    }.

%% Create a mentionable select menu (users + roles)
-spec mentionable_select(binary(), binary()) -> map().
mentionable_select(CustomId, Placeholder) ->
    #{
        <<"type">> => 7,  %% Mentionable Select
        <<"custom_id">> => CustomId,
        <<"placeholder">> => Placeholder
    }.

%% Create a channel select menu
-spec channel_select(binary(), binary()) -> map().
channel_select(CustomId, Placeholder) ->
    #{
        <<"type">> => 8,  %% Channel Select
        <<"custom_id">> => CustomId,
        <<"placeholder">> => Placeholder
    }.

%% ==========================================================
%% Modals
%% ==========================================================

%% Create a modal
-spec modal(binary(), binary()) -> map().
modal(CustomId, Title) ->
    #{
        <<"custom_id">> => CustomId,
        <<"title">> => Title,
        <<"components">> => []
    }.

%% Create a modal with components (action rows containing text inputs)
-spec modal(binary(), binary(), [map()]) -> map().
modal(CustomId, Title, Components) ->
    #{
        <<"custom_id">> => CustomId,
        <<"title">> => Title,
        <<"components">> => Components
    }.

%% ==========================================================
%% Slash Command Builder
%% ==========================================================

%% Command types
-define(CHAT_INPUT, 1).
-define(USER_COMMAND, 2).
-define(MESSAGE_COMMAND, 3).

%% Option types
-define(OPT_SUB_COMMAND, 1).
-define(OPT_SUB_COMMAND_GROUP, 2).
-define(OPT_STRING, 3).
-define(OPT_INTEGER, 4).
-define(OPT_BOOLEAN, 5).
-define(OPT_USER, 6).
-define(OPT_CHANNEL, 7).
-define(OPT_ROLE, 8).
-define(OPT_MENTIONABLE, 9).
-define(OPT_NUMBER, 10).
-define(OPT_ATTACHMENT, 11).

%% Create a slash command
-spec command(binary(), binary()) -> map().
command(Name, Description) ->
    #{
        <<"name">> => Name,
        <<"description">> => Description,
        <<"type">> => ?CHAT_INPUT
    }.

-spec command(binary(), binary(), [map()]) -> map().
command(Name, Description, Options) ->
    #{
        <<"name">> => Name,
        <<"description">> => Description,
        <<"type">> => ?CHAT_INPUT,
        <<"options">> => Options
    }.

%% Create a command option
%% Type: string | integer | boolean | user | channel | role | mentionable | number | attachment
-spec command_option(atom(), binary()) -> map().
command_option(Type, Name) ->
    command_option(Type, Name, #{}).

-spec command_option(atom(), binary(), map()) -> map().
command_option(Type, Name, Opts) ->
    TypeInt = option_type_to_int(Type),
    Description = maps:get(description, Opts, Name),
    Required = maps:get(required, Opts, false),
    Base = #{
        <<"type">> => TypeInt,
        <<"name">> => Name,
        <<"description">> => Description,
        <<"required">> => Required
    },
    %% Add optional fields
    OptionalFields = [choices, min_value, max_value, min_length, max_length, autocomplete, channel_types],
    lists:foldl(fun(Field, Acc) ->
        case maps:get(Field, Opts, undefined) of
            undefined -> Acc;
            Value -> Acc#{atom_to_binary(Field) => Value}
        end
    end, Base, OptionalFields).

%% Create a choice for string/integer options
-spec command_choice(binary(), binary() | integer()) -> map().
command_choice(Name, Value) ->
    #{<<"name">> => Name, <<"value">> => Value}.

%% Register a global command
-spec register_global_command(map()) -> discord_http:result().
register_global_command(Command) ->
    commands_http:create_global_command(Command).

%% Register a guild command
-spec register_guild_command(binary(), map()) -> discord_http:result().
register_guild_command(GuildId, Command) ->
    commands_http:create_guild_command(GuildId, Command).

%% Sync (bulk overwrite) global commands
-spec sync_global_commands([map()]) -> discord_http:result().
sync_global_commands(Commands) ->
    commands_http:bulk_overwrite_global_commands(Commands).

%% Sync (bulk overwrite) guild commands
-spec sync_guild_commands(binary(), [map()]) -> discord_http:result().
sync_guild_commands(GuildId, Commands) ->
    commands_http:bulk_overwrite_guild_commands(GuildId, Commands).

option_type_to_int(sub_command) -> ?OPT_SUB_COMMAND;
option_type_to_int(sub_command_group) -> ?OPT_SUB_COMMAND_GROUP;
option_type_to_int(string) -> ?OPT_STRING;
option_type_to_int(integer) -> ?OPT_INTEGER;
option_type_to_int(boolean) -> ?OPT_BOOLEAN;
option_type_to_int(user) -> ?OPT_USER;
option_type_to_int(channel) -> ?OPT_CHANNEL;
option_type_to_int(role) -> ?OPT_ROLE;
option_type_to_int(mentionable) -> ?OPT_MENTIONABLE;
option_type_to_int(number) -> ?OPT_NUMBER;
option_type_to_int(attachment) -> ?OPT_ATTACHMENT.

%% ==========================================================
%% Autocomplete
%% ==========================================================

%% Create an autocomplete choice
-spec autocomplete_choice(binary(), binary() | integer() | float()) -> map().
autocomplete_choice(Name, Value) ->
    #{<<"name">> => Name, <<"value">> => Value}.

%% ==========================================================
%% Cache Access
%% ==========================================================

%% Initialize the cache updater (call once after starting the application)
-spec init_cache() -> ok.
init_cache() ->
    cache_updater:init().

%% Get a guild from cache
-spec get_guild(binary()) -> {ok, map()} | {error, not_found}.
get_guild(GuildId) ->
    discord_cache:get_guild(GuildId).

%% Get a channel from cache
-spec get_channel(binary()) -> {ok, map()} | {error, not_found}.
get_channel(ChannelId) ->
    discord_cache:get_channel(ChannelId).

%% Get a user from cache
-spec get_user(binary()) -> {ok, map()} | {error, not_found}.
get_user(UserId) ->
    discord_cache:get_user(UserId).

%% Get a member from cache
-spec get_member(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_member(GuildId, UserId) ->
    discord_cache:get_member(GuildId, UserId).

%% Get a role from cache
-spec get_role(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_role(GuildId, RoleId) ->
    discord_cache:get_role(GuildId, RoleId).

%% Get cache statistics
-spec cache_stats() -> map().
cache_stats() ->
    discord_cache:stats().
