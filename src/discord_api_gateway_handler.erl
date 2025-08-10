%% ==========================================================
%% The main module for handling the events sent from the
%% Discord gateway API
%% ==========================================================
-module(discord_api_gateway_handler).

%% ==========================================================
%% Includes
%% ==========================================================

-include("discord_api_types.hrl").
-include("ws.hrl").
-include("logging.hrl").

%% ==========================================================
%% API
%% ==========================================================
-export([
    handle_gateway_event/5
]).

%% ==========================================================
%% Functions
%% ==========================================================
handle_gateway_event(?DISPATCH, D, S, T, State) ->
    ?DEBUG("Handling DISPATCH T=~p D=~p", [T, D]),
    notify_consumers(T, D),
    handle_dispatch(T, D, State#ws_conn_state{sequence_number = S});
handle_gateway_event(?HEARTBEAT, _, _, _, State) ->
    heartbeat:send_heartbeat(),
    State;
handle_gateway_event(?RECONNECT, _, _, _, State) ->
    discord_ws_conn:reconnect(resume, State);
handle_gateway_event(?INVALID_SESSION, _, _, _, State) ->
    State;
handle_gateway_event(?HELLO, D, _, _, State = #ws_conn_state{reconnect = Reconnect}) ->
    #{heartbeat_interval := HeartbeatInterval} = D,
    ?DEBUG("Starting heartbeat with an interval of ~pms", [HeartbeatInterval]),
    heartbeat:send_heartbeat(HeartbeatInterval),
    maybe_send_intents(Reconnect),
    State;
handle_gateway_event(?HEARTBEAT_ACK, _, _, _, State) ->
    State;
handle_gateway_event(UnknownOpcode, _, _, _, State) ->
    ?WARNING("Unknown Opcode: ~p", [UnknownOpcode]),
    State.

%% ==========================================================
%% Internal Functions
%% ==========================================================
handle_dispatch('RESUMED', _, State) ->
    ?DEBUG("Finished resuming the connection, setting state back to connected..."),
    State#ws_conn_state{reconnect = undefined};
handle_dispatch('READY', D, State) ->
    #{resume_gateway_url := ResumeGatewayUrl, session_id := SessionId} = D,
    ?DEBUG("Using resume_gateway_url: ~p and session_id: ~p", [ResumeGatewayUrl, SessionId]),
    State#ws_conn_state{resume_gateway_url = binary_to_list(binary:replace(ResumeGatewayUrl, <<"wss://">>, <<"">>)), session_id = SessionId};
handle_dispatch('INTERACTION_CREATE', Interaction, State) ->
    ParsedInteraction = discord_interaction_parser:map_to_interaction(Interaction),
    ?INFO("Parsed interaction: ~p", [ParsedInteraction]),
    interactions_registry:handle_interaction(ParsedInteraction),
    State;
handle_dispatch(_, _, State) ->
    State.

maybe_send_intents(resume) -> ok;
maybe_send_intents(_) -> dispatcher:send(intents:generate_intents_message()).

notify_consumers(T, D) ->
    case discord_events:get_function_handlers() of
        [] ->
            ok;
        Handlers ->
            [spawn(fun() -> Handler(T, D) end) || Handler <- Handlers]
    end,
    case discord_events:get_pid_handlers() of
        [] ->
            ok;
        Pids ->
            [gen_server:cast(Handler, {T, D}) || {Handler} <- Pids]
    end.
