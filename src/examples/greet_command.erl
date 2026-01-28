%% @doc Example: Command with options
%%
%% This example shows how to create a slash command with user input options.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register the command: greet_command:setup(GuildId).
%% 3. Use /greet @user in Discord to greet someone.
-module(greet_command).

-export([setup/1, handle/1]).

-include("discord_interaction.hrl").

%% @doc Register the /greet command for a guild
-spec setup(binary()) -> ok.
setup(GuildId) ->
    %% Create command with options
    Command = discord:command(<<"greet">>, <<"Greet another user">>, [
        discord:command_option(user, <<"user">>, #{
            description => <<"The user to greet">>,
            required => true
        }),
        discord:command_option(string, <<"message">>, #{
            description => <<"Custom greeting message">>,
            required => false
        })
    ]),

    case discord:register_guild_command(GuildId, Command) of
        {ok, #{<<"id">> := CommandId}} ->
            interactions_registry:register_function(CommandId, fun handle/1),
            io:format("Greet command registered with ID: ~s~n", [CommandId]),
            ok;
        {error, Reason} ->
            io:format("Failed to register command: ~p~n", [Reason]),
            error
    end.

%% @doc Handle the /greet interaction
-spec handle(#interaction{}) -> ok.
handle(Interaction = #interaction{data = Data}) ->
    #application_command_data{options = Options, resolved = Resolved} = Data,

    %% Extract the user option
    UserId = get_option_value(<<"user">>, Options),

    %% Get custom message or use default
    Message = case get_option_value(<<"message">>, Options) of
        undefined -> <<"Hello">>;
        Msg -> Msg
    end,

    %% Get user info from resolved data
    Username = case Resolved of
        #{<<"users">> := Users} ->
            case maps:get(UserId, Users, undefined) of
                undefined -> <<"someone">>;
                User -> maps:get(<<"username">>, User, <<"someone">>)
            end;
        _ -> <<"someone">>
    end,

    Response = <<Message/binary, ", ", Username/binary, "! 👋">>,
    discord:reply(Interaction, Response).

%% Helper to extract option value
get_option_value(Name, Options) ->
    case lists:keyfind(Name, #application_command_option.name, Options) of
        #application_command_option{value = Value} -> Value;
        false -> undefined
    end.
