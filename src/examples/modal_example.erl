%% @doc Example: Modal dialogs (popup forms)
%%
%% This example shows how to show modal dialogs and handle submissions.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register: modal_example:setup(GuildId).
%% 3. Use /feedback in Discord to open the feedback form.
-module(modal_example).

-export([setup/1]).

-include("discord_interaction.hrl").

%% @doc Register the feedback command and modal handler
-spec setup(binary()) -> ok.
setup(GuildId) ->
    %% Create the /feedback command
    Command = discord:command(<<"feedback">>, <<"Submit feedback about the bot">>),

    case discord:register_guild_command(GuildId, Command) of
        {ok, #{<<"id">> := CommandId}} ->
            %% Handle the command (shows the modal)
            interactions_registry:register_function(CommandId, fun show_modal/1),

            %% Handle the modal submission
            interactions_registry:register_function(<<"feedback_form">>, fun handle_submit/1),

            io:format("Feedback command registered with ID: ~s~n", [CommandId]),
            ok;
        {error, Reason} ->
            io:format("Failed to register command: ~p~n", [Reason]),
            error
    end.

%% @doc Show the feedback modal when /feedback is used
show_modal(Interaction) ->
    %% Create modal with text inputs
    %% Text inputs must be inside action rows
    Modal = discord:modal(<<"feedback_form">>, <<"Submit Feedback">>, [
        %% Short text input for subject
        discord:action_row([
            discord:text_input(<<"subject">>, <<"Subject">>, 1, #{
                <<"placeholder">> => <<"Brief description">>,
                <<"required">> => true,
                <<"min_length">> => 3,
                <<"max_length">> => 100
            })
        ]),
        %% Paragraph text input for details
        discord:action_row([
            discord:text_input(<<"details">>, <<"Details">>, 2, #{
                <<"placeholder">> => <<"Tell us more about your feedback...">>,
                <<"required">> => true,
                <<"min_length">> => 10,
                <<"max_length">> => 1000
            })
        ]),
        %% Optional rating
        discord:action_row([
            discord:text_input(<<"rating">>, <<"Rating (1-5)">>, 1, #{
                <<"placeholder">> => <<"Enter a number 1-5">>,
                <<"required">> => false,
                <<"max_length">> => 1
            })
        ])
    ]),

    discord:show_modal(Interaction, Modal).

%% @doc Handle the modal submission
handle_submit(Interaction = #interaction{data = Data}) ->
    #modal_submit_data{components = Components} = Data,

    %% Extract values from the submitted form
    Subject = get_text_input_value(<<"subject">>, Components),
    Details = get_text_input_value(<<"details">>, Components),
    Rating = get_text_input_value(<<"rating">>, Components),

    %% Create a nice response
    RatingStr = case Rating of
        undefined -> <<"Not rated">>;
        R -> <<R/binary, "/5">>
    end,

    Response = iolist_to_binary([
        <<"**Thank you for your feedback!**\n\n">>,
        <<"**Subject:** ">>, Subject, <<"\n">>,
        <<"**Rating:** ">>, RatingStr, <<"\n">>,
        <<"**Details:** ">>, Details
    ]),

    discord:reply_ephemeral(Interaction, Response).

%% Helper to extract text input value from modal components
get_text_input_value(CustomId, Components) ->
    %% Components are action rows containing the actual inputs
    lists:foldl(fun(ActionRow, Acc) ->
        case Acc of
            undefined ->
                InnerComponents = maps:get(<<"components">>, ActionRow, []),
                lists:foldl(fun(Component, InnerAcc) ->
                    case InnerAcc of
                        undefined ->
                            case maps:get(<<"custom_id">>, Component, undefined) of
                                CustomId -> maps:get(<<"value">>, Component, undefined);
                                _ -> undefined
                            end;
                        Found -> Found
                    end
                end, undefined, InnerComponents);
            Found -> Found
        end
    end, undefined, Components).
