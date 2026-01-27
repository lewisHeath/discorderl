-module(config).

-export([
    get_value/1,
    get_value/2,
    get_all/0,
    is_set/1
]).

-spec get_value(atom()) -> term().
get_value(Key) ->
    {ok, Value} = application:get_env(discorderl, Key),
    Value.

-spec get_value(atom(), term()) -> term().
get_value(Key, Default) ->
    case application:get_env(discorderl, Key) of
        {ok, Value} -> Value;
        _ -> Default
    end.

-spec get_all() -> [{atom(), term()}].
get_all() ->
    application:get_all_env(discorderl).

-spec is_set(atom()) -> boolean().
is_set(Key) ->
    case application:get_env(discorderl, Key) of
        {ok, _} -> true;
        undefined -> false
    end.
