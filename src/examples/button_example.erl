%% @doc Example: Interactive buttons
%%
%% This example shows how to create messages with buttons and handle clicks.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register handlers: button_example:setup().
%% 3. Send a message with buttons: button_example:send_poll(ChannelId).
-module(button_example).

-export([setup/0, send_poll/1]).

-include("discord_interaction.hrl").

%% @doc Register button click handlers
-spec setup() -> ok.
setup() ->
    %% Register handlers for each button's custom_id
    interactions_registry:register_function(<<"vote_yes">>, fun handle_vote_yes/1),
    interactions_registry:register_function(<<"vote_no">>, fun handle_vote_no/1),
    interactions_registry:register_function(<<"vote_maybe">>, fun handle_vote_maybe/1),
    io:format("Button handlers registered~n"),
    ok.

%% @doc Send a poll message with voting buttons
-spec send_poll(binary()) -> discord_http:result().
send_poll(ChannelId) ->
    %% Create buttons with different styles
    YesButton = discord:button(<<"vote_yes">>, <<"Yes">>, 3),      %% Green
    NoButton = discord:button(<<"vote_no">>, <<"No">>, 4),         %% Red
    MaybeButton = discord:button(<<"vote_maybe">>, <<"Maybe">>, 2), %% Grey

    %% Wrap in action row
    Row = discord:action_row([YesButton, NoButton, MaybeButton]),

    %% Create an embed for the poll
    Embed = discord:embed(),
    E1 = discord:embed_title(Embed, <<"Quick Poll">>),
    E2 = discord:embed_description(E1, <<"Do you like Erlang?">>),
    E3 = discord:embed_color(E2, 5814783),

    %% Send the message
    discord:send_message(ChannelId, <<"">>, #{
        embeds => [E3],
        components => [Row]
    }).

%% Button click handlers
handle_vote_yes(Interaction) ->
    %% Reply ephemerally (only the clicker sees it)
    discord:reply_ephemeral(Interaction, <<"You voted Yes! Great choice! 🎉">>).

handle_vote_no(Interaction) ->
    discord:reply_ephemeral(Interaction, <<"You voted No! That's okay too. 😊">>).

handle_vote_maybe(Interaction) ->
    discord:reply_ephemeral(Interaction, <<"You voted Maybe! Take your time to decide. 🤔">>).
