%% @doc Example: Select menus (dropdowns)
%%
%% This example shows how to create different types of select menus.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register: select_menu_example:setup(GuildId).
%% 3. Use /colors or /pick-user in Discord.
-module(select_menu_example).

-export([setup/1]).

-include("discord_interaction.hrl").

%% @doc Register commands and select menu handlers
-spec setup(binary()) -> ok.
setup(GuildId) ->
    %% String select menu example
    ColorsCmd = discord:command(<<"colors">>, <<"Pick your favorite color">>),
    case discord:register_guild_command(GuildId, ColorsCmd) of
        {ok, #{<<"id">> := ColorsCmdId}} ->
            interactions_registry:register_function(ColorsCmdId, fun show_color_menu/1),
            interactions_registry:register_function(<<"color_select">>, fun handle_color_select/1),
            io:format("Colors command registered~n");
        _ -> ok
    end,

    %% User select menu example
    PickUserCmd = discord:command(<<"pick-user">>, <<"Pick a user from the server">>),
    case discord:register_guild_command(GuildId, PickUserCmd) of
        {ok, #{<<"id">> := PickUserCmdId}} ->
            interactions_registry:register_function(PickUserCmdId, fun show_user_menu/1),
            interactions_registry:register_function(<<"user_select">>, fun handle_user_select/1),
            io:format("Pick-user command registered~n");
        _ -> ok
    end,

    ok.

%% @doc Show a string select menu with color options
show_color_menu(Interaction) ->
    Options = [
        discord:select_menu_option(<<"Red">>, <<"red">>, #{
            <<"description">> => <<"The color of passion">>,
            <<"emoji">> => #{<<"name">> => <<"🔴">>}
        }),
        discord:select_menu_option(<<"Green">>, <<"green">>, #{
            <<"description">> => <<"The color of nature">>,
            <<"emoji">> => #{<<"name">> => <<"🟢">>}
        }),
        discord:select_menu_option(<<"Blue">>, <<"blue">>, #{
            <<"description">> => <<"The color of the sky">>,
            <<"emoji">> => #{<<"name">> => <<"🔵">>}
        }),
        discord:select_menu_option(<<"Yellow">>, <<"yellow">>, #{
            <<"description">> => <<"The color of sunshine">>,
            <<"emoji">> => #{<<"name">> => <<"🟡">>}
        })
    ],

    Menu = discord:select_menu(<<"color_select">>, Options, <<"Choose your favorite color...">>),
    Row = discord:action_row([Menu]),

    discord:reply(Interaction, <<"Pick a color from the menu below:">>, #{
        components => [Row]
    }).

%% @doc Handle color selection
handle_color_select(Interaction = #interaction{data = Data}) ->
    #message_component_data{values = Values} = Data,

    Response = case Values of
        [Color | _] ->
            ColorEmoji = case Color of
                <<"red">> -> <<"🔴">>;
                <<"green">> -> <<"🟢">>;
                <<"blue">> -> <<"🔵">>;
                <<"yellow">> -> <<"🟡">>;
                _ -> <<"🎨">>
            end,
            <<ColorEmoji/binary, " You selected: **", Color/binary, "**!">>;
        [] ->
            <<"No color selected">>
    end,

    discord:reply_ephemeral(Interaction, Response).

%% @doc Show a user select menu
show_user_menu(Interaction) ->
    Menu = discord:user_select(<<"user_select">>, <<"Select a user...">>),
    Row = discord:action_row([Menu]),

    discord:reply(Interaction, <<"Pick a user from the server:">>, #{
        components => [Row]
    }).

%% @doc Handle user selection
handle_user_select(Interaction = #interaction{data = Data}) ->
    #message_component_data{values = Values} = Data,

    Response = case Values of
        [UserId | _] ->
            <<"You selected: <@", UserId/binary, ">!">>;
        [] ->
            <<"No user selected">>
    end,

    discord:reply_ephemeral(Interaction, Response).
