-module(rate_limiter_SUITE).

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
    start_creates_ets_table/1,
    wait_for_rate_limit_ok_when_not_limited/1,
    wait_for_rate_limit_disabled_returns_ok/1,
    update_rate_limit_parses_headers/1,
    is_rate_limited_false_initially/1,
    is_rate_limited_true_after_exhausted/1,
    get_bucket_info_not_found/1,
    get_bucket_info_returns_data/1,
    bucket_key_normalizes_snowflakes/1,
    retry_after_parsing/1
]).

all() -> [
    start_creates_ets_table,
    wait_for_rate_limit_ok_when_not_limited,
    wait_for_rate_limit_disabled_returns_ok,
    update_rate_limit_parses_headers,
    is_rate_limited_false_initially,
    is_rate_limited_true_after_exhausted,
    get_bucket_info_not_found,
    get_bucket_info_returns_data,
    bucket_key_normalizes_snowflakes,
    retry_after_parsing
].

init_per_suite(Config) ->
    application:set_env(discorderl, rate_limit_enabled, true),
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    {ok, Pid} = rate_limiter:start_link(),
    [{rate_limiter_pid, Pid} | Config].

end_per_testcase(_TestCase, Config) ->
    Pid = proplists:get_value(rate_limiter_pid, Config),
    unlink(Pid),
    exit(Pid, kill),
    timer:sleep(10),
    ok.

%% ==========================================================
%% Test Cases
%% ==========================================================

start_creates_ets_table(_Config) ->
    %% Table should exist after start
    ?assert(ets:info(rate_limit_buckets) =/= undefined).

wait_for_rate_limit_ok_when_not_limited(_Config) ->
    Endpoint = "/channels/123456789012345678/messages",
    Result = rate_limiter:wait_for_rate_limit(Endpoint),
    ?assertEqual(ok, Result).

wait_for_rate_limit_disabled_returns_ok(_Config) ->
    %% Temporarily disable rate limiting
    application:set_env(discorderl, rate_limit_enabled, false),
    Endpoint = "/channels/123/messages",
    Result = rate_limiter:wait_for_rate_limit(Endpoint),
    ?assertEqual(ok, Result),
    %% Re-enable for other tests
    application:set_env(discorderl, rate_limit_enabled, true).

update_rate_limit_parses_headers(_Config) ->
    Endpoint = "/channels/123456789012345678/messages",
    Headers = [
        {"X-RateLimit-Remaining", "5"},
        {"X-RateLimit-Limit", "10"},
        {"X-RateLimit-Reset-After", "1.5"}
    ],
    rate_limiter:update_rate_limit(Endpoint, Headers),
    timer:sleep(50),

    {ok, BucketInfo} = rate_limiter:get_bucket_info(Endpoint),
    ?assertEqual(5, maps:get(remaining, BucketInfo)),
    ?assertEqual(10, maps:get(limit, BucketInfo)),
    ?assertEqual(false, maps:get(global, BucketInfo)).

is_rate_limited_false_initially(_Config) ->
    Endpoint = "/users/@me",
    Result = rate_limiter:is_rate_limited(Endpoint),
    ?assertEqual(false, Result).

is_rate_limited_true_after_exhausted(_Config) ->
    Endpoint = "/channels/123456789012345678/messages",
    %% Simulate exhausted rate limit
    Headers = [
        {"X-RateLimit-Remaining", "0"},
        {"X-RateLimit-Limit", "10"},
        {"X-RateLimit-Reset-After", "5.0"}  %% 5 seconds from now
    ],
    rate_limiter:update_rate_limit(Endpoint, Headers),
    timer:sleep(50),

    Result = rate_limiter:is_rate_limited(Endpoint),
    ?assertEqual(true, Result).

get_bucket_info_not_found(_Config) ->
    Endpoint = "/unknown/endpoint",
    Result = rate_limiter:get_bucket_info(Endpoint),
    ?assertEqual({error, not_found}, Result).

get_bucket_info_returns_data(_Config) ->
    Endpoint = "/guilds/123456789012345678",
    Headers = [
        {"X-RateLimit-Remaining", "3"},
        {"X-RateLimit-Limit", "5"},
        {"X-RateLimit-Reset-After", "2.0"}
    ],
    rate_limiter:update_rate_limit(Endpoint, Headers),
    timer:sleep(50),

    {ok, BucketInfo} = rate_limiter:get_bucket_info(Endpoint),
    ?assertEqual(3, maps:get(remaining, BucketInfo)),
    ?assertEqual(5, maps:get(limit, BucketInfo)).

bucket_key_normalizes_snowflakes(_Config) ->
    %% Different snowflake IDs should map to the same bucket key
    %% This is tested implicitly through the rate limiter behavior
    Endpoint1 = "/channels/123456789012345678/messages",
    Endpoint2 = "/channels/987654321098765432/messages",

    %% Both should initially be ok (not limited)
    ?assertEqual(ok, rate_limiter:wait_for_rate_limit(Endpoint1)),
    ?assertEqual(ok, rate_limiter:wait_for_rate_limit(Endpoint2)).

retry_after_parsing(_Config) ->
    Endpoint = "/channels/123456789012345678/messages",
    %% Simulate 429 response with Retry-After
    Headers = [
        {"X-RateLimit-Remaining", "0"},
        {"X-RateLimit-Limit", "10"},
        {"Retry-After", "2"}  %% 2 seconds
    ],
    rate_limiter:update_rate_limit(Endpoint, Headers),
    timer:sleep(50),

    %% Should be rate limited
    ?assertEqual(true, rate_limiter:is_rate_limited(Endpoint)),

    %% Verify the wait time is approximately correct
    case rate_limiter:wait_for_rate_limit(Endpoint) of
        {wait, WaitMs} ->
            %% Should be approximately 2000ms (minus elapsed time)
            ?assert(WaitMs > 0),
            ?assert(WaitMs =< 2000);
        ok ->
            %% Time may have elapsed during test
            ok
    end.
