%% @doc Example: Simple ping command
%%
%% This example shows how to create and register a basic slash command.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register the command: ping_command:setup(GuildId).
%% 3. The command will be available as /ping in Discord.
-module(ping_command).

-export([setup/1, handle/1]).

-include("discord_interaction.hrl").

%% @doc Register the /ping command for a guild
-spec setup(binary()) -> ok.
setup(GuildId) ->
    %% Create the command definition
    Command = discord:command(<<"ping">>, <<"Check if the bot is alive">>),

    %% Register it with Discord
    case discord:register_guild_command(GuildId, Command) of
        {ok, #{<<"id">> := CommandId}} ->
            %% Register our handler for this command
            interactions_registry:register_function(CommandId, fun handle/1),
            io:format("Ping command registered with ID: ~s~n", [CommandId]),
            ok;
        {error, Reason} ->
            io:format("Failed to register command: ~p~n", [Reason]),
            error
    end.

%% @doc Handle the /ping interaction
-spec handle(#interaction{}) -> ok.
handle(Interaction) ->
    %% Calculate a simple "latency" (time since interaction was created)
    discord:reply(Interaction, <<"Pong! 🏓 Bot is alive and responding.">>).
