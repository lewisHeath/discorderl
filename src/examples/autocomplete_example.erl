%% @doc Example: Autocomplete suggestions
%%
%% This example shows how to provide autocomplete suggestions as users type.
%%
%% Setup:
%% 1. Start the application: application:ensure_all_started(discorderl).
%% 2. Register: autocomplete_example:setup(GuildId).
%% 3. Use /country and start typing to see suggestions.
-module(autocomplete_example).

-export([setup/1]).

-include("discord_interaction.hrl").

%% Sample data for autocomplete
-define(COUNTRIES, [
    {<<"United States">>, <<"us">>},
    {<<"United Kingdom">>, <<"uk">>},
    {<<"Germany">>, <<"de">>},
    {<<"France">>, <<"fr">>},
    {<<"Japan">>, <<"jp">>},
    {<<"Australia">>, <<"au">>},
    {<<"Canada">>, <<"ca">>},
    {<<"Brazil">>, <<"br">>},
    {<<"India">>, <<"in">>},
    {<<"China">>, <<"cn">>},
    {<<"Mexico">>, <<"mx">>},
    {<<"Spain">>, <<"es">>},
    {<<"Italy">>, <<"it">>},
    {<<"Netherlands">>, <<"nl">>},
    {<<"Sweden">>, <<"se">>}
]).

%% @doc Register the country command with autocomplete
-spec setup(binary()) -> ok.
setup(GuildId) ->
    Command = discord:command(<<"country">>, <<"Get information about a country">>, [
        discord:command_option(string, <<"name">>, #{
            description => <<"Country name">>,
            required => true,
            autocomplete => true  %% Enable autocomplete!
        })
    ]),

    case discord:register_guild_command(GuildId, Command) of
        {ok, #{<<"id">> := CommandId}} ->
            %% Single handler for both autocomplete and command execution
            interactions_registry:register_function(CommandId, fun handle/1),
            io:format("Country command registered with ID: ~s~n", [CommandId]),
            ok;
        {error, Reason} ->
            io:format("Failed to register command: ~p~n", [Reason]),
            error
    end.

%% @doc Handle both autocomplete requests and command execution
handle(Interaction = #interaction{type = Type, data = Data}) ->
    case Type of
        4 -> %% APPLICATION_COMMAND_AUTOCOMPLETE
            handle_autocomplete(Interaction, Data);
        2 -> %% APPLICATION_COMMAND
            handle_command(Interaction, Data);
        _ ->
            ok
    end.

%% @doc Provide autocomplete suggestions based on user input
handle_autocomplete(Interaction, #autocomplete_data{options = Options}) ->
    %% Find the focused option (what the user is currently typing)
    FocusedValue = get_focused_value(Options),

    %% Filter countries that match the input
    Suggestions = filter_countries(FocusedValue),

    %% Convert to autocomplete choices (max 25)
    Choices = lists:sublist([
        discord:autocomplete_choice(Name, Code)
        || {Name, Code} <- Suggestions
    ], 25),

    discord:autocomplete(Interaction, Choices).

%% @doc Handle the actual command execution
handle_command(Interaction, #application_command_data{options = Options}) ->
    CountryCode = get_option_value(<<"name">>, Options),

    %% Find the country name from the code
    CountryName = case lists:keyfind(CountryCode, 2, ?COUNTRIES) of
        {Name, _} -> Name;
        false -> CountryCode  %% User typed something custom
    end,

    %% Create a response with "country info"
    Embed = discord:embed(),
    E1 = discord:embed_title(Embed, <<"Country Information">>),
    E2 = discord:embed_field(E1, <<"Country">>, CountryName, true),
    E3 = discord:embed_field(E2, <<"Code">>, CountryCode, true),
    E4 = discord:embed_color(E3, 3447003),

    discord:reply(Interaction, <<"">>, #{embeds => [E4]}).

%% Helper: Get the value of the option that is currently focused
get_focused_value(Options) ->
    case lists:filter(fun(Opt) ->
        Opt#application_command_option.focused =:= true
    end, Options) of
        [#application_command_option{value = Value} | _] when Value =/= undefined ->
            string:lowercase(binary_to_list(Value));
        _ ->
            ""
    end.

%% Helper: Filter countries based on input
filter_countries(Input) when Input =:= "" ->
    ?COUNTRIES;
filter_countries(Input) ->
    lists:filter(fun({Name, _Code}) ->
        string:find(string:lowercase(binary_to_list(Name)), Input) =/= nomatch
    end, ?COUNTRIES).

%% Helper: Get option value by name
get_option_value(Name, Options) ->
    case lists:keyfind(Name, #application_command_option.name, Options) of
        #application_command_option{value = Value} -> Value;
        false -> undefined
    end.
