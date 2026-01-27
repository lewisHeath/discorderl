-module(discord_interaction_parser_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("discord_interaction.hrl").

%% CT callbacks
-export([
    all/0,
    init_per_suite/1,
    end_per_suite/1
]).

%% Test cases
-export([
    parse_basic_interaction/1,
    parse_interaction_with_user/1,
    parse_interaction_with_member/1,
    parse_interaction_with_message/1,
    parse_application_command_data/1,
    parse_command_options/1,
    parse_component_data/1,
    parse_missing_optional_fields/1,
    parse_nested_user_in_member/1
]).

all() -> [
    parse_basic_interaction,
    parse_interaction_with_user,
    parse_interaction_with_member,
    parse_interaction_with_message,
    parse_application_command_data,
    parse_command_options,
    parse_component_data,
    parse_missing_optional_fields,
    parse_nested_user_in_member
].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

%% ==========================================================
%% Test Cases
%% ==========================================================

parse_basic_interaction(_Config) ->
    Map = #{
        <<"id">> => <<"12345678901234567">>,
        <<"application_id">> => <<"98765432109876543">>,
        <<"type">> => 1,  %% PING type (doesn't require data)
        <<"token">> => <<"test_token">>,
        <<"version">> => 1
    },
    Result = discord_interaction_parser:map_to_interaction(Map),
    ?assertEqual(<<"12345678901234567">>, Result#interaction.id),
    ?assertEqual(<<"98765432109876543">>, Result#interaction.application_id),
    ?assertEqual(1, Result#interaction.type),
    ?assertEqual(<<"test_token">>, Result#interaction.token),
    ?assertEqual(1, Result#interaction.version).

parse_interaction_with_user(_Config) ->
    UserMap = #{
        <<"id">> => <<"user123">>,
        <<"username">> => <<"testuser">>,
        <<"discriminator">> => <<"1234">>,
        <<"global_name">> => <<"Test User">>,
        <<"avatar">> => <<"abc123">>,
        <<"bot">> => false
    },
    Result = discord_interaction_parser:map_to_user(UserMap),
    ?assertEqual(<<"user123">>, Result#user.id),
    ?assertEqual(<<"testuser">>, Result#user.username),
    ?assertEqual(<<"1234">>, Result#user.discriminator),
    ?assertEqual(<<"Test User">>, Result#user.global_name),
    ?assertEqual(<<"abc123">>, Result#user.avatar),
    ?assertEqual(false, Result#user.bot).

parse_interaction_with_member(_Config) ->
    MemberMap = #{
        <<"nick">> => <<"nickname">>,
        <<"roles">> => [<<"role1">>, <<"role2">>],
        <<"joined_at">> => <<"2021-01-01T00:00:00.000000+00:00">>,
        <<"deaf">> => false,
        <<"mute">> => false
    },
    Result = discord_interaction_parser:map_to_guild_member(MemberMap),
    ?assertEqual(<<"nickname">>, Result#guild_member.nick),
    ?assertEqual([<<"role1">>, <<"role2">>], Result#guild_member.roles),
    ?assertEqual(<<"2021-01-01T00:00:00.000000+00:00">>, Result#guild_member.joined_at),
    ?assertEqual(false, Result#guild_member.deaf),
    ?assertEqual(false, Result#guild_member.mute).

parse_interaction_with_message(_Config) ->
    AuthorMap = #{
        <<"id">> => <<"author123">>,
        <<"username">> => <<"author">>
    },
    MessageMap = #{
        <<"id">> => <<"msg123">>,
        <<"channel_id">> => <<"chan123">>,
        <<"author">> => AuthorMap,
        <<"content">> => <<"Hello, world!">>,
        <<"timestamp">> => <<"2021-01-01T00:00:00.000000+00:00">>,
        <<"tts">> => false,
        <<"mention_everyone">> => false,
        <<"pinned">> => false,
        <<"type">> => 0
    },
    Result = discord_interaction_parser:map_to_message(MessageMap),
    ?assertEqual(<<"msg123">>, Result#message.id),
    ?assertEqual(<<"chan123">>, Result#message.channel_id),
    ?assertEqual(<<"Hello, world!">>, Result#message.content),
    ?assertEqual(false, Result#message.tts).

parse_application_command_data(_Config) ->
    DataMap = #{
        <<"id">> => <<"cmd123">>,
        <<"name">> => <<"testcmd">>,
        <<"type">> => 1,
        <<"options">> => []
    },
    Result = discord_interaction_parser:map_to_app_command_data(DataMap),
    ?assertEqual(<<"cmd123">>, Result#application_command_data.id),
    ?assertEqual(<<"testcmd">>, Result#application_command_data.name),
    ?assertEqual(1, Result#application_command_data.type),
    ?assertEqual([], Result#application_command_data.options).

parse_command_options(_Config) ->
    OptionMap = #{
        <<"name">> => <<"option1">>,
        <<"type">> => 3,
        <<"value">> => <<"some value">>,
        <<"focused">> => false
    },
    Result = discord_interaction_parser:map_to_command_option(OptionMap),
    ?assertEqual(<<"option1">>, Result#application_command_option.name),
    ?assertEqual(3, Result#application_command_option.type),
    ?assertEqual(<<"some value">>, Result#application_command_option.value),
    ?assertEqual(false, Result#application_command_option.focused).

parse_component_data(_Config) ->
    ComponentMap = #{
        <<"custom_id">> => <<"button_1">>,
        <<"component_type">> => 2,
        <<"values">> => []
    },
    Result = discord_interaction_parser:map_to_component_data(ComponentMap),
    ?assertEqual(<<"button_1">>, Result#message_component_data.custom_id),
    ?assertEqual(2, Result#message_component_data.component_type),
    ?assertEqual([], Result#message_component_data.values).

parse_missing_optional_fields(_Config) ->
    %% Test that missing optional fields default properly
    MinimalUser = #{
        <<"id">> => <<"user123">>,
        <<"username">> => <<"testuser">>
    },
    Result = discord_interaction_parser:map_to_user(MinimalUser),
    ?assertEqual(<<"user123">>, Result#user.id),
    ?assertEqual(<<"testuser">>, Result#user.username),
    ?assertEqual(<<"0">>, Result#user.discriminator),  %% default
    ?assertEqual(undefined, Result#user.global_name),
    ?assertEqual(undefined, Result#user.avatar),
    ?assertEqual(false, Result#user.bot).  %% default

parse_nested_user_in_member(_Config) ->
    MemberMap = #{
        <<"user">> => #{
            <<"id">> => <<"nested_user">>,
            <<"username">> => <<"nestedname">>
        },
        <<"nick">> => <<"nick">>,
        <<"roles">> => [],
        <<"joined_at">> => <<"2021-01-01T00:00:00.000000+00:00">>
    },
    Result = discord_interaction_parser:map_to_guild_member(MemberMap),
    ?assertMatch(#user{id = <<"nested_user">>}, Result#guild_member.user).
