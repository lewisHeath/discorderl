-module(discord_events_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

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
    register_function_handler_success/1,
    register_function_handler_invalid/1,
    register_pid_handler_success/1,
    register_pid_handler_invalid/1,
    get_function_handlers_empty/1,
    get_function_handlers_with_handlers/1,
    get_pid_handlers_empty/1,
    get_pid_handlers_with_handlers/1,
    multiple_handlers_same_event/1
]).

all() -> [
    register_function_handler_success,
    register_function_handler_invalid,
    register_pid_handler_success,
    register_pid_handler_invalid,
    get_function_handlers_empty,
    get_function_handlers_with_handlers,
    get_pid_handlers_empty,
    get_pid_handlers_with_handlers,
    multiple_handlers_same_event
].

init_per_suite(Config) ->
    application:ensure_all_started(lager),
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    {ok, Pid} = discord_events:start_link(),
    [{discord_events_pid, Pid} | Config].

end_per_testcase(_TestCase, Config) ->
    Pid = proplists:get_value(discord_events_pid, Config),
    unlink(Pid),
    exit(Pid, kill),
    %% Wait for process to terminate
    timer:sleep(10),
    ok.

%% ==========================================================
%% Test Cases
%% ==========================================================

register_function_handler_success(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    Handler = fun(_Event, _Type) -> ok end,
    %% Should not crash (cast returns ok)
    discord_events:register_function_handler(EventType, Handler),
    %% Give time for the cast to process
    timer:sleep(50),
    Handlers = discord_events:get_function_handlers(),
    ?assert(maps:is_key(EventType, Handlers)).

register_function_handler_invalid(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    InvalidHandler = fun(_) -> ok end,  %% Only 1 arity, needs 2
    ?assertError({invalid_function_handler, InvalidHandler},
                 discord_events:register_function_handler(EventType, InvalidHandler)).

register_pid_handler_success(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    discord_events:register_pid_handler(EventType, self()),
    timer:sleep(50),
    Handlers = discord_events:get_pid_handlers(),
    ?assert(maps:is_key(EventType, Handlers)),
    ?assert(lists:member(self(), maps:get(EventType, Handlers))).

register_pid_handler_invalid(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    ?assertError({invalid_pid_handler, not_a_pid},
                 discord_events:register_pid_handler(EventType, not_a_pid)).

get_function_handlers_empty(_Config) ->
    Handlers = discord_events:get_function_handlers(),
    ?assertEqual(#{}, Handlers).

get_function_handlers_with_handlers(_Config) ->
    EventType1 = <<"MESSAGE_CREATE">>,
    EventType2 = <<"GUILD_CREATE">>,
    Handler1 = fun(_E, _T) -> handler1 end,
    Handler2 = fun(_E, _T) -> handler2 end,

    discord_events:register_function_handler(EventType1, Handler1),
    discord_events:register_function_handler(EventType2, Handler2),
    timer:sleep(50),

    Handlers = discord_events:get_function_handlers(),
    ?assert(maps:is_key(EventType1, Handlers)),
    ?assert(maps:is_key(EventType2, Handlers)).

get_pid_handlers_empty(_Config) ->
    Handlers = discord_events:get_pid_handlers(),
    ?assertEqual(#{}, Handlers).

get_pid_handlers_with_handlers(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    discord_events:register_pid_handler(EventType, self()),
    timer:sleep(50),

    Handlers = discord_events:get_pid_handlers(),
    ?assertEqual(#{EventType => [self()]}, Handlers).

multiple_handlers_same_event(_Config) ->
    EventType = <<"MESSAGE_CREATE">>,
    Handler1 = fun(_E, _T) -> handler1 end,
    Handler2 = fun(_E, _T) -> handler2 end,

    discord_events:register_function_handler(EventType, Handler1),
    discord_events:register_function_handler(EventType, Handler2),
    timer:sleep(50),

    Handlers = discord_events:get_function_handlers(),
    EventHandlers = maps:get(EventType, Handlers),
    %% Should have 2 handlers for this event
    ?assertEqual(2, length(EventHandlers)).
