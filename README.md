# Discorderl

A production-ready Discord bot library for Erlang/OTP.

## Features

- WebSocket gateway connection with automatic heartbeat and reconnection
- HTTP REST API with rate limiting and automatic retry
- Slash command support with easy command builder
- Interaction handling (commands, buttons, select menus, modals, autocomplete)
- Event-driven architecture with flexible handler registration
- Ergonomic helper module for common operations
- Comprehensive embed and component builders
- Bot presence/status management
- Guild/channel/user caching with automatic updates

## Installation

### Using erlang.mk

Add discorderl as a dependency in your `Makefile`:

```makefile
DEPS = discorderl
dep_discorderl = git https://github.com/yourusername/discorderl.git main
```

Then run:

```bash
make deps
```

### Using rebar3

Add to your `rebar.config`:

```erlang
{deps, [
    {discorderl, {git, "https://github.com/yourusername/discorderl.git", {branch, "main"}}}
]}.
```

## Configuration

### sys.config

Configure discorderl in your `config/sys.config`:

```erlang
[
    {discorderl, [
        %% Required: Gateway intents
        {intents, ['GUILDS', 'GUILD_MESSAGES', 'MESSAGE_CONTENT']},

        %% Required for slash commands: Your application ID
        {application_id, <<"YOUR_APPLICATION_ID">>},

        %% Optional: HTTP request timeout (default: 30000ms)
        {http_timeout, 30000},

        %% Optional: Max retries on rate limit (default: 3)
        {http_retries, 3},

        %% Optional: WebSocket dispatch delay (default: 500ms)
        {ws_dispatch_delay, 500},

        %% Optional: Enable/disable rate limiting (default: true)
        {rate_limit_enabled, true}
    ]}
].
```

### Environment Variables

Set your bot token as an environment variable:

```bash
export DISCORD_BOT_TOKEN="your_bot_token_here"
```

### Available Intents

- `'GUILDS'`
- `'GUILD_MEMBERS'`
- `'GUILD_MODERATION'`
- `'GUILD_EMOJIS_AND_STICKERS'`
- `'GUILD_INTEGRATIONS'`
- `'GUILD_WEBHOOKS'`
- `'GUILD_INVITES'`
- `'GUILD_VOICE_STATES'`
- `'GUILD_PRESENCES'`
- `'GUILD_MESSAGES'`
- `'GUILD_MESSAGE_REACTIONS'`
- `'GUILD_MESSAGE_TYPING'`
- `'DIRECT_MESSAGES'`
- `'DIRECT_MESSAGE_REACTIONS'`
- `'DIRECT_MESSAGE_TYPING'`
- `'MESSAGE_CONTENT'`
- `'GUILD_SCHEDULED_EVENTS'`
- `'AUTO_MODERATION_CONFIGURATION'`
- `'AUTO_MODERATION_EXECUTION'`

## Quick Start

### Starting the Application

```erlang
%% Start the application
application:ensure_all_started(discorderl).
```

### Responding to Slash Commands

Register a handler for your slash command:

```erlang
%% Register a module handler
interactions_registry:register_module(<<"command_id">>, my_handler_module).

%% Or register a function handler
interactions_registry:register_function(<<"command_id">>, fun(Interaction) ->
    discord:reply(Interaction, <<"Hello from Erlang!">>)
end).

%% Or register a pid to receive messages
interactions_registry:register_pid(<<"command_id">>, self()).
```

### Handler Module Example

```erlang
-module(my_handler_module).
-behaviour(discord_interaction_handler).
-export([handle_interaction/1]).

-include("discord_interaction.hrl").

handle_interaction(Interaction = #interaction{data = Data}) ->
    #application_command_data{name = CommandName} = Data,
    case CommandName of
        <<"ping">> ->
            discord:reply(Interaction, <<"Pong!">>);
        <<"greet">> ->
            discord:reply_ephemeral(Interaction, <<"Hello! Only you can see this.">>);
        _ ->
            discord:reply(Interaction, <<"Unknown command">>)
    end.
```

### Sending Messages

```erlang
%% Simple message
discord:send_message(ChannelId, <<"Hello, Discord!">>).

%% Message with embed
Embed = discord:embed(),
Embed1 = discord:embed_title(Embed, <<"Welcome!">>),
Embed2 = discord:embed_description(Embed1, <<"This is a description">>),
Embed3 = discord:embed_color(Embed2, 16711680),  %% Red
discord:send_message(ChannelId, <<"">>, #{embeds => [Embed3]}).

%% Edit a message
discord:edit_message(ChannelId, MessageId, <<"Updated content">>).

%% Delete a message
discord:delete_message(ChannelId, MessageId).
```

### Using Embeds (Fluent API)

```erlang
Embed = discord:embed(),
Embed1 = discord:embed_title(Embed, <<"My Embed">>),
Embed2 = discord:embed_description(Embed1, <<"A detailed description">>),
Embed3 = discord:embed_color(Embed2, 3447003),  %% Blue
Embed4 = discord:embed_field(Embed3, <<"Field 1">>, <<"Value 1">>),
Embed5 = discord:embed_field(Embed4, <<"Field 2">>, <<"Value 2">>, true),  %% Inline
Embed6 = discord:embed_footer(Embed5, <<"Footer text">>),
Embed7 = discord:embed_thumbnail(Embed6, <<"https://example.com/image.png">>).
```

### Using Components (Buttons, Select Menus)

```erlang
%% Create buttons
Button1 = discord:button(<<"btn_yes">>, <<"Yes">>, 3),    %% Success (green)
Button2 = discord:button(<<"btn_no">>, <<"No">>, 4),      %% Danger (red)
LinkBtn = discord:button_link(<<"https://example.com">>, <<"Visit Site">>),

%% Create an action row with buttons
Row = discord:action_row([Button1, Button2, LinkBtn]),

%% Send message with components
discord:reply(Interaction, <<"Choose an option:">>, #{components => [Row]}).
```

### Event Handling

```erlang
%% Register a function handler for MESSAGE_CREATE events
discord_events:register_function_handler(<<"MESSAGE_CREATE">>, fun(Event, _Type) ->
    Content = maps:get(<<"content">>, Event, <<"">>),
    io:format("New message: ~s~n", [Content])
end).

%% Register a pid handler
discord_events:register_pid_handler(<<"GUILD_MEMBER_ADD">>, self()).
```

### Bot Presence/Status

```erlang
%% Set bot status
discord:set_status(online).      %% online | idle | dnd | invisible

%% Set activity
discord:set_activity(playing, <<"Erlang">>).
discord:set_activity(watching, <<"the logs">>).
discord:set_activity(listening, <<"commands">>).
discord:set_activity(competing, <<"a hackathon">>).

%% Full presence control
discord:set_presence(#{
    status => <<"dnd">>,
    activities => [#{<<"type">> => 0, <<"name">> => <<"with OTP">>}],
    afk => false
}).
```

### Slash Command Builder

```erlang
%% Create a simple command
PingCmd = discord:command(<<"ping">>, <<"Check bot latency">>).

%% Create a command with options
GreetCmd = discord:command(<<"greet">>, <<"Greet a user">>, [
    discord:command_option(user, <<"target">>, #{
        description => <<"User to greet">>,
        required => true
    }),
    discord:command_option(string, <<"message">>, #{
        description => <<"Custom message">>,
        required => false
    })
]).

%% Register commands
discord:register_guild_command(GuildId, PingCmd).
discord:register_global_command(GreetCmd).

%% Sync all commands at once (replaces existing)
discord:sync_guild_commands(GuildId, [PingCmd, GreetCmd]).
```

### Modals

```erlang
%% Show a modal when button is clicked
interactions_registry:register_function(<<"open_form">>, fun(Interaction) ->
    Modal = discord:modal(<<"my_form">>, <<"Feedback Form">>, [
        discord:action_row([
            discord:text_input(<<"name">>, <<"Your Name">>, 1)  %% 1=Short
        ]),
        discord:action_row([
            discord:text_input(<<"feedback">>, <<"Your Feedback">>, 2)  %% 2=Paragraph
        ])
    ]),
    discord:show_modal(Interaction, Modal)
end).

%% Handle modal submission
interactions_registry:register_function(<<"my_form">>, fun(Interaction) ->
    discord:reply_ephemeral(Interaction, <<"Thanks for your feedback!">>)
end).
```

### Select Menus

```erlang
%% String select menu
Options = [
    discord:select_menu_option(<<"Option 1">>, <<"opt1">>),
    discord:select_menu_option(<<"Option 2">>, <<"opt2">>, #{
        description => <<"This is option 2">>,
        default => true
    })
],
Menu = discord:select_menu(<<"my_select">>, Options, <<"Choose an option">>),
Row = discord:action_row([Menu]),
discord:reply(Interaction, <<"Pick one:">>, #{components => [Row]}).

%% Other select types
UserMenu = discord:user_select(<<"pick_user">>, <<"Select a user">>),
RoleMenu = discord:role_select(<<"pick_role">>, <<"Select a role">>),
ChannelMenu = discord:channel_select(<<"pick_channel">>, <<"Select a channel">>).
```

### Autocomplete

```erlang
%% Create command with autocomplete
Cmd = discord:command(<<"search">>, <<"Search something">>, [
    discord:command_option(string, <<"query">>, #{
        description => <<"Search query">>,
        required => true,
        autocomplete => true
    })
]).

%% Handle autocomplete
interactions_registry:register_function(CmdId, fun(Interaction = #interaction{type = 4}) ->
    %% Type 4 = autocomplete
    Choices = [
        discord:autocomplete_choice(<<"Result 1">>, <<"value1">>),
        discord:autocomplete_choice(<<"Result 2">>, <<"value2">>)
    ],
    discord:autocomplete(Interaction, Choices);
(Interaction) ->
    %% Normal command execution
    discord:reply(Interaction, <<"You searched!">>)
end).
```

### Caching

```erlang
%% Initialize cache (call once after starting)
discord:init_cache().

%% Access cached data
{ok, Guild} = discord:get_guild(GuildId).
{ok, Channel} = discord:get_channel(ChannelId).
{ok, User} = discord:get_user(UserId).
{ok, Member} = discord:get_member(GuildId, UserId).
{ok, Role} = discord:get_role(GuildId, RoleId).

%% Get cache statistics
Stats = discord:cache_stats().
%% #{guilds => 5, channels => 50, users => 100, members => 200, roles => 25}
```

## API Reference

### discord module (Helper Functions)

#### Interaction Responses

| Function | Description |
|----------|-------------|
| `discord:reply(Interaction, Content)` | Reply to an interaction |
| `discord:reply(Interaction, Content, Opts)` | Reply with options (embeds, components) |
| `discord:reply_ephemeral(Interaction, Content)` | Reply with ephemeral message |
| `discord:defer(Interaction)` | Defer response (show "thinking...") |
| `discord:defer_ephemeral(Interaction)` | Defer with ephemeral flag |
| `discord:followup(Interaction, Content)` | Send followup message |
| `discord:edit_response(Interaction, Content)` | Edit original response |
| `discord:delete_response(Interaction)` | Delete original response |
| `discord:update_message(Interaction, Data)` | Update component's parent message |
| `discord:show_modal(Interaction, Modal)` | Show a modal dialog |
| `discord:autocomplete(Interaction, Choices)` | Respond to autocomplete |

#### Messages

| Function | Description |
|----------|-------------|
| `discord:send_message(ChannelId, Content)` | Send a message |
| `discord:send_message(ChannelId, Content, Opts)` | Send with embeds/components |
| `discord:edit_message(ChannelId, MsgId, Data)` | Edit a message |
| `discord:delete_message(ChannelId, MsgId)` | Delete a message |

#### Embed Builder

| Function | Description |
|----------|-------------|
| `discord:embed()` | Create empty embed |
| `discord:embed_title(Embed, Title)` | Set title |
| `discord:embed_description(Embed, Desc)` | Set description |
| `discord:embed_color(Embed, Color)` | Set color (integer) |
| `discord:embed_field(Embed, Name, Value)` | Add field |
| `discord:embed_field(Embed, Name, Value, Inline)` | Add field with inline |
| `discord:embed_footer(Embed, Text)` | Set footer |
| `discord:embed_image(Embed, Url)` | Set image |
| `discord:embed_thumbnail(Embed, Url)` | Set thumbnail |
| `discord:embed_author(Embed, Name)` | Set author |

#### Components

| Function | Description |
|----------|-------------|
| `discord:action_row(Components)` | Create action row |
| `discord:button(CustomId, Label, Style)` | Create button (1-4) |
| `discord:button_link(Url, Label)` | Create link button |
| `discord:button_disabled(CustomId, Label, Style)` | Create disabled button |
| `discord:button_emoji(CustomId, Label, Style, Emoji)` | Button with emoji |
| `discord:select_menu(CustomId, Options, Placeholder)` | String select menu |
| `discord:select_menu_option(Label, Value)` | Select menu option |
| `discord:user_select(CustomId, Placeholder)` | User select menu |
| `discord:role_select(CustomId, Placeholder)` | Role select menu |
| `discord:channel_select(CustomId, Placeholder)` | Channel select menu |
| `discord:mentionable_select(CustomId, Placeholder)` | User/role select |
| `discord:text_input(CustomId, Label, Style)` | Text input for modals |
| `discord:modal(CustomId, Title, Components)` | Create modal |

#### Presence

| Function | Description |
|----------|-------------|
| `discord:set_status(Status)` | Set online/idle/dnd/invisible |
| `discord:set_activity(Type, Name)` | Set activity (playing, watching, etc.) |
| `discord:set_presence(Opts)` | Full presence control |

#### Command Builder

| Function | Description |
|----------|-------------|
| `discord:command(Name, Description)` | Create slash command |
| `discord:command(Name, Description, Options)` | Command with options |
| `discord:command_option(Type, Name, Opts)` | Create command option |
| `discord:command_choice(Name, Value)` | Create option choice |
| `discord:register_global_command(Cmd)` | Register global command |
| `discord:register_guild_command(GuildId, Cmd)` | Register guild command |
| `discord:sync_global_commands(Commands)` | Bulk overwrite global |
| `discord:sync_guild_commands(GuildId, Commands)` | Bulk overwrite guild |

#### Cache

| Function | Description |
|----------|-------------|
| `discord:init_cache()` | Initialize cache updater |
| `discord:get_guild(GuildId)` | Get cached guild |
| `discord:get_channel(ChannelId)` | Get cached channel |
| `discord:get_user(UserId)` | Get cached user |
| `discord:get_member(GuildId, UserId)` | Get cached member |
| `discord:get_role(GuildId, RoleId)` | Get cached role |
| `discord:cache_stats()` | Get cache statistics |

### HTTP Modules

#### messages_http

- `create_message/2`, `get_message/2`, `edit_message/3`, `delete_message/2`
- `bulk_delete_messages/2`
- `create_reaction/3`, `delete_own_reaction/3`, `delete_user_reaction/4`
- `get_reactions/3`, `delete_all_reactions/2`
- `pin_message/2`, `unpin_message/2`, `get_pinned_messages/1`

#### commands_http

- `get_global_commands/0`, `create_global_command/1`, `edit_global_command/2`, `delete_global_command/1`
- `bulk_overwrite_global_commands/1`
- `get_guild_commands/1`, `create_guild_command/2`, `edit_guild_command/3`, `delete_guild_command/2`
- `bulk_overwrite_guild_commands/2`
- `get_guild_command_permissions/1`, `get_command_permissions/2`, `edit_command_permissions/3`

#### users_http

- `get_current_user/0`, `get_user/1`, `modify_current_user/1`
- `create_dm/1`
- `get_current_user_guilds/0`, `get_current_user_connections/0`

#### guilds_http

- `get_guild/1`, `modify_guild/2`
- `get_guild_channels/1`, `create_guild_channel/2`
- `get_guild_member/2`, `list_guild_members/1`, `modify_guild_member/3`
- `get_guild_roles/1`, `create_guild_role/2`, `modify_guild_role/3`, `delete_guild_role/2`
- `get_guild_bans/1`, `get_guild_ban/2`, `create_guild_ban/2`, `remove_guild_ban/2`
- `add_guild_member_role/3`, `remove_guild_member_role/3`

#### channels_http

- `get_channel/1`, `modify_channel/2`, `delete_channel/1`
- `get_channel_messages/1`, `trigger_typing_indicator/1`
- `edit_channel_permissions/3`, `delete_channel_permission/2`
- `start_thread_with_message/3`, `start_thread_without_message/2`
- `join_thread/1`, `leave_thread/1`

### Configuration Module

```erlang
%% Get a config value (crashes if not set)
config:get_value(intents).

%% Get with default
config:get_value(http_timeout, 30000).

%% Check if key is set
config:is_set(application_id).  %% true | false

%% Get all config
config:get_all().  %% [{Key, Value}, ...]
```

## Architecture

```
discorderl_app
    └── discord_api_sup (supervisor)
            ├── rate_limiter (gen_server) - Rate limit management
            ├── discord_cache (gen_server) - Guild/channel/user caching
            ├── discord_ws_conn (gen_server) - WebSocket with auto-reconnect
            ├── heartbeat (gen_server) - Gateway heartbeat
            ├── dispatcher (gen_server) - Message queue dispatch
            └── discord_events (gen_server) - Event handler registry

HTTP Modules (stateless):
    ├── discord_http - Core HTTP client with rate limiting
    ├── interaction_http - Interaction responses
    ├── messages_http - Channel messages
    ├── commands_http - Slash commands
    ├── users_http - User operations
    ├── guilds_http - Guild operations
    └── channels_http - Channel operations

Cache:
    ├── discord_cache - ETS-based cache storage
    └── cache_updater - Auto-updates from gateway events

Helper:
    └── discord - Ergonomic API wrapper
```

## Rate Limiting

Discorderl automatically handles Discord's rate limits:

- Per-endpoint bucket tracking
- Global rate limit detection
- Automatic retry with exponential backoff
- Configurable retry count

Rate limiting is enabled by default. To disable:

```erlang
{rate_limit_enabled, false}
```

## Testing

Run the test suites:

```bash
make ct
```

Individual test suites:

```bash
make ct-discord_interaction_parser
make ct-interactions_registry
make ct-discord_events
make ct-discord_http
make ct-rate_limiter
```

## License

MIT License
