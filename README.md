# Discorderl

A production-ready Discord bot library for Erlang/OTP.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Discord Setup](#discord-setup)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Rate Limiting](#rate-limiting)
- [Caching](#caching)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- **WebSocket Gateway** - Automatic heartbeat, reconnection with exponential backoff
- **HTTP REST API** - Full rate limiting with automatic retry
- **Slash Commands** - Easy command builder with options and autocomplete
- **Interactions** - Commands, buttons, select menus, modals, autocomplete
- **Event System** - Flexible handler registration for gateway events
- **Helper Module** - Ergonomic API for common operations
- **Components** - Embeds, buttons, select menus, modals, text inputs
- **Presence** - Bot status and activity management
- **Caching** - Guild/channel/user caching with automatic updates

## Requirements

- Erlang/OTP 24 or later
- A Discord bot application and token

## Installation

### Using erlang.mk

Add discorderl as a dependency in your `Makefile`:

```makefile
PROJECT = mybot
DEPS = discorderl

dep_discorderl = git https://github.com/yourusername/discorderl.git main

include erlang.mk
```

Then run:

```bash
make deps app
```

### Using rebar3

Add to your `rebar.config`:

```erlang
{deps, [
    {discorderl, {git, "https://github.com/yourusername/discorderl.git", {branch, "main"}}}
]}.
```

Then run:

```bash
rebar3 compile
```

## Discord Setup

Before using discorderl, you need to create a Discord application and bot:

### 1. Create an Application

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications)
2. Click "New Application" and give it a name
3. Note your **Application ID** (you'll need this for slash commands)

### 2. Create a Bot

1. Go to the "Bot" section in your application
2. Click "Add Bot"
3. Under the bot's username, click "Reset Token" to get your bot token
4. **Save this token securely** - you won't be able to see it again!

### 3. Configure Intents

In the Bot section, enable the intents your bot needs:

- **Server Members Intent** - For `GUILD_MEMBERS` events
- **Message Content Intent** - To read message content (required for `MESSAGE_CONTENT` intent)
- **Presence Intent** - For `GUILD_PRESENCES` events

### 4. Invite the Bot

1. Go to "OAuth2" > "URL Generator"
2. Select scopes: `bot`, `applications.commands`
3. Select bot permissions as needed
4. Copy the URL and open it to invite the bot to your server

### 5. Get Your Guild ID

To register guild-specific commands during development:

1. Enable Developer Mode in Discord (Settings > Advanced > Developer Mode)
2. Right-click your server name and "Copy Server ID"

## Configuration

### Environment Variables

Set your bot token:

```bash
export DISCORD_BOT_TOKEN="your_bot_token_here"
```

### sys.config

Create or edit `config/sys.config`:

```erlang
[
    {discorderl, [
        %% Required: Gateway intents (list of atoms)
        {intents, ['GUILDS', 'GUILD_MESSAGES', 'MESSAGE_CONTENT']},

        %% Required for slash commands
        {application_id, <<"YOUR_APPLICATION_ID">>},

        %% Optional settings with defaults
        {http_timeout, 30000},        %% HTTP request timeout (ms)
        {http_retries, 3},            %% Retries on rate limit
        {ws_dispatch_delay, 500},     %% Event dispatch delay (ms)
        {rate_limit_enabled, true}    %% Enable rate limiting
    ]},

    %% Logging configuration
    {lager, [
        {handlers, [
            {lager_file_backend, [{file, "log/discorderl.log"}, {level, info}]}
        ]}
    ]}
].
```

### Available Intents

| Intent | Description |
|--------|-------------|
| `'GUILDS'` | Guild create/update/delete, channel events |
| `'GUILD_MEMBERS'` | Member add/update/remove (privileged) |
| `'GUILD_MODERATION'` | Ban add/remove, audit log |
| `'GUILD_EMOJIS_AND_STICKERS'` | Emoji/sticker events |
| `'GUILD_INTEGRATIONS'` | Integration events |
| `'GUILD_WEBHOOKS'` | Webhook events |
| `'GUILD_INVITES'` | Invite create/delete |
| `'GUILD_VOICE_STATES'` | Voice state updates |
| `'GUILD_PRESENCES'` | Presence updates (privileged) |
| `'GUILD_MESSAGES'` | Message create/update/delete |
| `'GUILD_MESSAGE_REACTIONS'` | Reaction events |
| `'GUILD_MESSAGE_TYPING'` | Typing start events |
| `'DIRECT_MESSAGES'` | DM message events |
| `'DIRECT_MESSAGE_REACTIONS'` | DM reaction events |
| `'DIRECT_MESSAGE_TYPING'` | DM typing events |
| `'MESSAGE_CONTENT'` | Read message content (privileged) |
| `'GUILD_SCHEDULED_EVENTS'` | Scheduled event CRUD |
| `'AUTO_MODERATION_CONFIGURATION'` | AutoMod rule events |
| `'AUTO_MODERATION_EXECUTION'` | AutoMod execution events |

**Note:** Privileged intents require enabling in the Discord Developer Portal.

## Quick Start

### 1. Start the Application

```erlang
%% In your Erlang shell
1> application:ensure_all_started(discorderl).
{ok, [ssl, inets, gun, jsx, lager, discorderl]}
```

### 2. Create a Simple Command

```erlang
%% Create a /ping command
2> PingCmd = discord:command(<<"ping">>, <<"Check if the bot is alive">>).

%% Register it to your guild (faster for testing)
3> discord:register_guild_command(<<"YOUR_GUILD_ID">>, PingCmd).
{ok, #{<<"id">> := CommandId, ...}}

%% Set up the handler
4> interactions_registry:register_function(CommandId, fun(Interaction) ->
       discord:reply(Interaction, <<"Pong!">>)
   end).
ok
```

### 3. Test It

Type `/ping` in your Discord server. The bot should respond with "Pong!"

## Examples

The `src/examples/` directory contains complete examples demonstrating various features:

| Example | Description |
|---------|-------------|
| [ping_command.erl](src/examples/ping_command.erl) | Simple slash command |
| [greet_command.erl](src/examples/greet_command.erl) | Command with options |
| [button_example.erl](src/examples/button_example.erl) | Interactive buttons |
| [modal_example.erl](src/examples/modal_example.erl) | Modal dialogs (forms) |
| [select_menu_example.erl](src/examples/select_menu_example.erl) | Dropdown menus |
| [autocomplete_example.erl](src/examples/autocomplete_example.erl) | Autocomplete suggestions |
| [presence_example.erl](src/examples/presence_example.erl) | Bot status/activity |
| [cache_example.erl](src/examples/cache_example.erl) | Using the cache |
| [event_handler_example.erl](src/examples/event_handler_example.erl) | Gateway event handling |

### Running Examples

```erlang
%% Start the application
1> application:ensure_all_started(discorderl).

%% Set up a slash command example
2> ping_command:setup(<<"YOUR_GUILD_ID">>).

%% Set up button example
3> button_example:setup().
4> button_example:send_poll(<<"CHANNEL_ID">>).

%% Set bot status
5> presence_example:set_playing(<<"Erlang">>).
```

## API Reference

### discord module (Helper Functions)

#### Interaction Responses

```erlang
%% Reply to an interaction
discord:reply(Interaction, <<"Hello!">>).
discord:reply(Interaction, <<"Hello!">>, #{embeds => [Embed]}).

%% Ephemeral reply (only visible to the user)
discord:reply_ephemeral(Interaction, <<"Secret message">>).

%% Defer (show "Bot is thinking...")
discord:defer(Interaction).
discord:defer_ephemeral(Interaction).

%% Follow-up messages
discord:followup(Interaction, <<"More info...">>).

%% Edit the original response
discord:edit_response(Interaction, <<"Updated!">>).
discord:delete_response(Interaction).

%% Update the message a component is on
discord:update_message(Interaction, #{content => <<"Updated!">>}).

%% Show a modal
discord:show_modal(Interaction, Modal).

%% Respond to autocomplete
discord:autocomplete(Interaction, Choices).
```

#### Messages

```erlang
%% Send a message
discord:send_message(ChannelId, <<"Hello!">>).
discord:send_message(ChannelId, <<"">>, #{
    embeds => [Embed],
    components => [ActionRow]
}).

%% Edit a message
discord:edit_message(ChannelId, MessageId, <<"Updated">>).
discord:edit_message(ChannelId, MessageId, #{content => <<"Updated">>}).

%% Delete a message
discord:delete_message(ChannelId, MessageId).
```

#### Embed Builder (Fluent API)

```erlang
Embed = discord:embed(),
E1 = discord:embed_title(Embed, <<"My Title">>),
E2 = discord:embed_description(E1, <<"A description">>),
E3 = discord:embed_color(E2, 16711680),  %% Red (hex: 0xFF0000)
E4 = discord:embed_field(E3, <<"Field Name">>, <<"Field Value">>),
E5 = discord:embed_field(E4, <<"Inline Field">>, <<"Value">>, true),
E6 = discord:embed_footer(E5, <<"Footer text">>),
E7 = discord:embed_image(E6, <<"https://example.com/image.png">>),
E8 = discord:embed_thumbnail(E7, <<"https://example.com/thumb.png">>),
E9 = discord:embed_author(E8, <<"Author Name">>),
Final = discord:embed_url(E9, <<"https://example.com">>).
```

#### Components

```erlang
%% Buttons (Style: 1=Primary, 2=Secondary, 3=Success, 4=Danger)
Button = discord:button(<<"custom_id">>, <<"Click Me">>, 1).
LinkBtn = discord:button_link(<<"https://example.com">>, <<"Visit">>).
DisabledBtn = discord:button_disabled(<<"id">>, <<"Disabled">>, 2).
EmojiBtn = discord:button_emoji(<<"id">>, <<"Vote">>, 1, <<"👍">>).

%% Action row (max 5 buttons or 1 select menu)
Row = discord:action_row([Button1, Button2, Button3]).

%% String select menu
Options = [
    discord:select_menu_option(<<"Label">>, <<"value">>),
    discord:select_menu_option(<<"Label 2">>, <<"value2">>, #{
        description => <<"Description">>,
        default => true
    })
],
Menu = discord:select_menu(<<"select_id">>, Options, <<"Placeholder...">>).

%% Other select types
UserMenu = discord:user_select(<<"user_select">>, <<"Pick a user">>).
RoleMenu = discord:role_select(<<"role_select">>, <<"Pick a role">>).
ChannelMenu = discord:channel_select(<<"channel_select">>, <<"Pick a channel">>).
MentionableMenu = discord:mentionable_select(<<"mention_select">>, <<"Pick...">>).

%% Text input (for modals) - Style: 1=Short, 2=Paragraph
Input = discord:text_input(<<"input_id">>, <<"Label">>, 1).
Input2 = discord:text_input(<<"input_id">>, <<"Label">>, 2, #{
    <<"placeholder">> => <<"Enter text...">>,
    <<"required">> => true,
    <<"min_length">> => 1,
    <<"max_length">> => 100
}).

%% Modal
Modal = discord:modal(<<"modal_id">>, <<"Form Title">>, [
    discord:action_row([discord:text_input(<<"name">>, <<"Name">>, 1)]),
    discord:action_row([discord:text_input(<<"bio">>, <<"Bio">>, 2)])
]).
```

#### Slash Command Builder

```erlang
%% Simple command
Cmd = discord:command(<<"ping">>, <<"Ping the bot">>).

%% Command with options
Cmd2 = discord:command(<<"greet">>, <<"Greet someone">>, [
    discord:command_option(user, <<"target">>, #{
        description => <<"Who to greet">>,
        required => true
    }),
    discord:command_option(string, <<"message">>, #{
        description => <<"Custom message">>,
        required => false
    })
]).

%% Option with choices
Cmd3 = discord:command(<<"color">>, <<"Pick a color">>, [
    discord:command_option(string, <<"color">>, #{
        description => <<"Your choice">>,
        required => true,
        choices => [
            discord:command_choice(<<"Red">>, <<"red">>),
            discord:command_choice(<<"Blue">>, <<"blue">>),
            discord:command_choice(<<"Green">>, <<"green">>)
        ]
    })
]).

%% Option with autocomplete
Cmd4 = discord:command(<<"search">>, <<"Search">>, [
    discord:command_option(string, <<"query">>, #{
        description => <<"Search query">>,
        required => true,
        autocomplete => true
    })
]).

%% Register commands
discord:register_guild_command(GuildId, Cmd).     %% Guild-specific (instant)
discord:register_global_command(Cmd).              %% Global (up to 1 hour)

%% Bulk sync (replaces all commands)
discord:sync_guild_commands(GuildId, [Cmd1, Cmd2, Cmd3]).
discord:sync_global_commands([Cmd1, Cmd2]).
```

Option types: `string`, `integer`, `boolean`, `user`, `channel`, `role`, `mentionable`, `number`, `attachment`

#### Presence

```erlang
%% Set status
discord:set_status(online).     %% Green dot
discord:set_status(idle).       %% Yellow dot
discord:set_status(dnd).        %% Red dot
discord:set_status(invisible).  %% Offline

%% Set activity
discord:set_activity(playing, <<"Erlang">>).
discord:set_activity(watching, <<"the logs">>).
discord:set_activity(listening, <<"/help">>).
discord:set_activity(competing, <<"a hackathon">>).
discord:set_activity(streaming, <<"Live!">>, #{<<"url">> => <<"https://twitch.tv/...">>}).

%% Full presence control
discord:set_presence(#{
    status => <<"dnd">>,
    activities => [#{<<"type">> => 0, <<"name">> => <<"with fire">>}],
    afk => false
}).
```

#### Cache

```erlang
%% Initialize cache auto-updater (call once)
discord:init_cache().

%% Get cached data
{ok, Guild} = discord:get_guild(GuildId).
{ok, Channel} = discord:get_channel(ChannelId).
{ok, User} = discord:get_user(UserId).
{ok, Member} = discord:get_member(GuildId, UserId).
{ok, Role} = discord:get_role(GuildId, RoleId).
{ok, Channels} = discord:get_guild_channels(GuildId).

%% Get statistics
Stats = discord:cache_stats().
%% #{guilds => 5, channels => 100, users => 500, members => 1000, roles => 50}
```

### HTTP Modules

These modules provide direct access to Discord's REST API:

#### messages_http

```erlang
messages_http:create_message(ChannelId, #{<<"content">> => <<"Hello">>}).
messages_http:get_message(ChannelId, MessageId).
messages_http:edit_message(ChannelId, MessageId, #{<<"content">> => <<"Updated">>}).
messages_http:delete_message(ChannelId, MessageId).
messages_http:bulk_delete_messages(ChannelId, [MsgId1, MsgId2]).

%% Reactions
messages_http:create_reaction(ChannelId, MessageId, <<"👍">>).
messages_http:delete_own_reaction(ChannelId, MessageId, <<"👍">>).
messages_http:get_reactions(ChannelId, MessageId, <<"👍">>).
messages_http:delete_all_reactions(ChannelId, MessageId).

%% Pins
messages_http:pin_message(ChannelId, MessageId).
messages_http:unpin_message(ChannelId, MessageId).
messages_http:get_pinned_messages(ChannelId).
```

#### commands_http

```erlang
%% Global commands
commands_http:get_global_commands().
commands_http:create_global_command(CommandData).
commands_http:edit_global_command(CommandId, Updates).
commands_http:delete_global_command(CommandId).
commands_http:bulk_overwrite_global_commands([Cmd1, Cmd2]).

%% Guild commands
commands_http:get_guild_commands(GuildId).
commands_http:create_guild_command(GuildId, CommandData).
commands_http:edit_guild_command(GuildId, CommandId, Updates).
commands_http:delete_guild_command(GuildId, CommandId).
commands_http:bulk_overwrite_guild_commands(GuildId, [Cmd1, Cmd2]).

%% Permissions
commands_http:get_guild_command_permissions(GuildId).
commands_http:get_command_permissions(GuildId, CommandId).
commands_http:edit_command_permissions(GuildId, CommandId, Permissions).
```

#### users_http

```erlang
users_http:get_current_user().
users_http:get_user(UserId).
users_http:modify_current_user(#{<<"username">> => <<"NewName">>}).
users_http:create_dm(UserId).
users_http:get_current_user_guilds().
```

#### guilds_http

```erlang
guilds_http:get_guild(GuildId).
guilds_http:modify_guild(GuildId, #{<<"name">> => <<"New Name">>}).
guilds_http:get_guild_channels(GuildId).
guilds_http:create_guild_channel(GuildId, #{<<"name">> => <<"new-channel">>}).

%% Members
guilds_http:get_guild_member(GuildId, UserId).
guilds_http:list_guild_members(GuildId).
guilds_http:modify_guild_member(GuildId, UserId, #{<<"nick">> => <<"Nickname">>}).

%% Roles
guilds_http:get_guild_roles(GuildId).
guilds_http:create_guild_role(GuildId, #{<<"name">> => <<"New Role">>}).
guilds_http:add_guild_member_role(GuildId, UserId, RoleId).
guilds_http:remove_guild_member_role(GuildId, UserId, RoleId).

%% Bans
guilds_http:get_guild_bans(GuildId).
guilds_http:create_guild_ban(GuildId, UserId).
guilds_http:remove_guild_ban(GuildId, UserId).
```

#### channels_http

```erlang
channels_http:get_channel(ChannelId).
channels_http:modify_channel(ChannelId, #{<<"name">> => <<"new-name">>}).
channels_http:delete_channel(ChannelId).
channels_http:get_channel_messages(ChannelId).
channels_http:trigger_typing_indicator(ChannelId).

%% Threads
channels_http:start_thread_with_message(ChannelId, MessageId, #{<<"name">> => <<"Thread">>}).
channels_http:start_thread_without_message(ChannelId, #{<<"name">> => <<"Thread">>}).
channels_http:join_thread(ThreadId).
channels_http:leave_thread(ThreadId).
```

### Handler Registration

```erlang
%% Register a module (must implement discord_interaction_handler behaviour)
interactions_registry:register_module(CommandId, my_handler_module).

%% Register a function
interactions_registry:register_function(CommandId, fun(Interaction) ->
    discord:reply(Interaction, <<"Hello!">>)
end).

%% Register a pid (receives {interaction, Interaction} messages)
interactions_registry:register_pid(CommandId, self()).

%% For components (buttons, select menus), use the custom_id
interactions_registry:register_function(<<"my_button_id">>, fun handle_click/1).

%% For modals, use the modal's custom_id
interactions_registry:register_function(<<"my_modal_id">>, fun handle_submit/1).
```

### Event Handling

```erlang
%% Register for gateway events
discord_events:register_handler('MESSAGE_CREATE', fun(Data) ->
    Content = maps:get(<<"content">>, Data, <<"">>),
    io:format("Message: ~s~n", [Content])
end).

discord_events:register_handler('GUILD_MEMBER_ADD', fun(Data) ->
    User = maps:get(<<"user">>, Data),
    Username = maps:get(<<"username">>, User),
    io:format("~s joined!~n", [Username])
end).

%% Available events (partial list):
%% READY, GUILD_CREATE, GUILD_UPDATE, GUILD_DELETE
%% CHANNEL_CREATE, CHANNEL_UPDATE, CHANNEL_DELETE
%% MESSAGE_CREATE, MESSAGE_UPDATE, MESSAGE_DELETE
%% GUILD_MEMBER_ADD, GUILD_MEMBER_UPDATE, GUILD_MEMBER_REMOVE
%% PRESENCE_UPDATE, TYPING_START, VOICE_STATE_UPDATE
%% INTERACTION_CREATE (handled automatically by interactions_registry)
```

## Architecture

```
discorderl_app
    └── discord_api_sup (supervisor)
            ├── rate_limiter     - Rate limit tracking and enforcement
            ├── discord_cache    - ETS-based guild/channel/user cache
            ├── discord_ws_conn  - WebSocket with auto-reconnect
            ├── heartbeat        - Gateway heartbeat
            ├── dispatcher       - Event dispatch queue
            └── discord_events   - Event handler registry

HTTP (stateless modules):
    discord_http      - Core HTTP client with rate limiting
    interaction_http  - Interaction responses
    messages_http     - Channel messages
    commands_http     - Slash commands
    users_http        - User operations
    guilds_http       - Guild operations
    channels_http     - Channel operations

Cache:
    discord_cache   - ETS storage (guilds, channels, users, members, roles)
    cache_updater   - Auto-updates cache from gateway events

Interactions:
    interactions_registry        - Handler dispatch
    discord_interaction_parser   - Payload to record conversion

Helper:
    discord          - Ergonomic API wrapper
    config           - Configuration access
```

## Rate Limiting

Discorderl automatically handles Discord's rate limits:

- **Per-endpoint tracking** - Each route has its own bucket
- **Global rate limits** - Detected and respected
- **Automatic retry** - Failed requests retry with exponential backoff
- **Header parsing** - Reads `X-RateLimit-*` headers

Rate limiting is enabled by default. Configure behavior:

```erlang
{discorderl, [
    {rate_limit_enabled, true},  %% Toggle rate limiting
    {http_retries, 3}            %% Max retries on 429
]}
```

## Caching

The cache system stores Discord data locally for fast access:

```erlang
%% Initialize (registers gateway event handlers)
discord:init_cache().

%% The cache auto-populates from:
%% - GUILD_CREATE (when bot joins/reconnects)
%% - CHANNEL_CREATE/UPDATE/DELETE
%% - GUILD_MEMBER_ADD/UPDATE/REMOVE
%% - etc.

%% Query the cache
{ok, Guild} = discord:get_guild(GuildId).
{error, not_found} = discord:get_guild(<<"invalid_id">>).

%% Cache statistics
Stats = discord:cache_stats().
%% #{guilds => 10, channels => 250, users => 5000, ...}
```

## Testing

Run all tests:

```bash
make ct
```

Run specific suites:

```bash
make ct-discord_interaction_parser
make ct-interactions_registry
make ct-discord_events
make ct-discord_http
make ct-rate_limiter
```

## Troubleshooting

### "Token not found" error

Ensure the `DISCORD_BOT_TOKEN` environment variable is set:

```bash
export DISCORD_BOT_TOKEN="your_token"
```

### Commands not appearing

- Guild commands appear instantly; global commands take up to 1 hour
- Ensure the bot has `applications.commands` scope
- Check if `application_id` is configured correctly

### "Missing Access" or "Missing Permissions"

- The bot lacks required permissions in the channel/guild
- Re-invite with proper permissions via OAuth2 URL Generator

### Not receiving MESSAGE_CREATE events

- Enable `MESSAGE_CONTENT` intent in config AND Discord Developer Portal
- Ensure the bot can see the channel

### Rate limit errors (429)

- This is normal; the library auto-retries
- If persistent, you may be making too many requests
- Check `http_retries` config

### WebSocket disconnects

- The library auto-reconnects with exponential backoff
- Max 10 attempts before giving up
- Check network connectivity and bot token validity

### Cache returning `not_found`

- Call `discord:init_cache()` after starting the application
- Wait for `GUILD_CREATE` events (bot needs to receive guild data)
- The bot must be in the guild to cache its data

### Interaction failed / "This interaction failed"

- Handler must respond within 3 seconds
- Use `discord:defer(Interaction)` for long operations
- Check logs for errors in handler function

### Debug logging

Add to sys.config:

```erlang
{lager, [
    {handlers, [
        {lager_console_backend, [{level, debug}]},
        {lager_file_backend, [{file, "log/debug.log"}, {level, debug}]}
    ]}
]}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make ct`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
