-module(interactions_registry_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("discord_interaction.hrl").

%% CT callbacks
-export([
    all/0,
    init_per_suite/1,
    end_per_suite/1,
    init_per_testcase/2,
    end_per_testcase/2
]).

%% Test cases
-export([
    start_creates_ets_tables/1,
    stop_deletes_ets_tables/1,
    register_module_success/1,
    register_module_already_registered/1,
    register_function_success/1,
    register_function_already_registered/1,
    register_pid_success/1,
    register_pid_multiple_pids/1,
    handle_interaction_calls_module/1,
    handle_interaction_calls_function/1,
    handle_interaction_sends_to_pid/1
]).

all() -> [
    start_creates_ets_tables,
    stop_deletes_ets_tables,
    register_module_success,
    register_module_already_registered,
    register_function_success,
    register_function_already_registered,
    register_pid_success,
    register_pid_multiple_pids,
    handle_interaction_calls_module,
    handle_interaction_calls_function,
    handle_interaction_sends_to_pid
].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    %% Start the registry for each test
    catch interactions_registry:stop(),
    interactions_registry:start(),
    Config.

end_per_testcase(_TestCase, _Config) ->
    %% Clean up after each test
    catch interactions_registry:stop(),
    ok.

%% ==========================================================
%% Test Cases
%% ==========================================================

start_creates_ets_tables(_Config) ->
    %% Tables should exist after start (called in init_per_testcase)
    ?assert(ets:info(interactions_modules) =/= undefined),
    ?assert(ets:info(interactions_functions) =/= undefined),
    ?assert(ets:info(interactions_pids) =/= undefined).

stop_deletes_ets_tables(_Config) ->
    interactions_registry:stop(),
    ?assertEqual(undefined, ets:info(interactions_modules)),
    ?assertEqual(undefined, ets:info(interactions_functions)),
    ?assertEqual(undefined, ets:info(interactions_pids)),
    %% Restart for cleanup
    interactions_registry:start().

register_module_success(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    Result = interactions_registry:register_module(InteractionId, test_module),
    ?assertEqual(ok, Result),
    %% Verify it was stored
    ?assertEqual([{InteractionId, test_module}], ets:lookup(interactions_modules, InteractionId)).

register_module_already_registered(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    ok = interactions_registry:register_module(InteractionId, first_module),
    Result = interactions_registry:register_module(InteractionId, second_module),
    ?assertEqual({error, already_registered}, Result),
    %% First module should still be registered
    ?assertEqual([{InteractionId, first_module}], ets:lookup(interactions_modules, InteractionId)).

register_function_success(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    Fun = fun(_Interaction) -> ok end,
    Result = interactions_registry:register_function(InteractionId, Fun),
    ?assertEqual(ok, Result),
    %% Verify it was stored
    [{_, StoredFun}] = ets:lookup(interactions_functions, InteractionId),
    ?assert(is_function(StoredFun)).

register_function_already_registered(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    Fun1 = fun(_) -> first end,
    Fun2 = fun(_) -> second end,
    ok = interactions_registry:register_function(InteractionId, Fun1),
    Result = interactions_registry:register_function(InteractionId, Fun2),
    ?assertEqual({error, already_registered}, Result).

register_pid_success(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    Result = interactions_registry:register_pid(InteractionId, self()),
    ?assertEqual(ok, Result),
    %% Verify it was stored
    ?assertEqual([{InteractionId, [self()]}], ets:lookup(interactions_pids, InteractionId)).

register_pid_multiple_pids(_Config) ->
    InteractionId = <<"test_cmd_id">>,
    Pid1 = self(),
    Pid2 = spawn(fun() -> receive stop -> ok end end),

    ok = interactions_registry:register_pid(InteractionId, Pid1),
    ok = interactions_registry:register_pid(InteractionId, Pid2),

    [{_, Pids}] = ets:lookup(interactions_pids, InteractionId),
    ?assert(lists:member(Pid1, Pids)),
    ?assert(lists:member(Pid2, Pids)),

    %% Cleanup spawned process
    Pid2 ! stop.

handle_interaction_calls_module(_Config) ->
    %% This test would need a mock module
    %% For now, just verify no crash when module not found
    Interaction = make_test_interaction(<<"unknown_id">>),
    %% Should not crash
    interactions_registry:handle_interaction(Interaction).

handle_interaction_calls_function(_Config) ->
    InteractionId = <<"func_test_id">>,
    Self = self(),
    Fun = fun(I) -> Self ! {called, I} end,

    ok = interactions_registry:register_function(InteractionId, Fun),

    Interaction = make_test_interaction(InteractionId),
    interactions_registry:handle_interaction(Interaction),

    receive
        {called, ReceivedInteraction} ->
            ?assertEqual(InteractionId, (ReceivedInteraction#interaction.data)#application_command_data.id)
    after 1000 ->
        ct:fail("Function was not called within timeout")
    end.

handle_interaction_sends_to_pid(_Config) ->
    InteractionId = <<"pid_test_id">>,

    ok = interactions_registry:register_pid(InteractionId, self()),

    Interaction = make_test_interaction(InteractionId),
    interactions_registry:handle_interaction(Interaction),

    receive
        ReceivedInteraction when is_record(ReceivedInteraction, interaction) ->
            ?assertEqual(InteractionId, (ReceivedInteraction#interaction.data)#application_command_data.id)
    after 1000 ->
        ct:fail("Message was not received within timeout")
    end.

%% ==========================================================
%% Helper Functions
%% ==========================================================

make_test_interaction(CommandId) ->
    #interaction{
        id = <<"interaction_123">>,
        application_id = <<"app_123">>,
        type = 2,
        data = #application_command_data{
            id = CommandId,
            name = <<"testcmd">>,
            type = 1,
            options = []
        },
        token = <<"test_token">>,
        version = 1
    }.
