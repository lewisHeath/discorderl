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
-include("discord_interaction.hrl").

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
    discord_events:publish(T, D),
    State1 = handle_dispatch(T, D, State#ws_conn_state{sequence_number = S}),
    State1;
handle_gateway_event(?HEARTBEAT, _, _, _, State) ->
    heartbeat:send_heartbeat(),
    State;
handle_gateway_event(?RECONNECT, _, _, _, State) ->
    discord_ws_conn:reconnect(resume, State);
handle_gateway_event(?INVALID_SESSION, _, _, _, State) ->
    % TODO
    State;
handle_gateway_event(?HELLO, #{heartbeat_interval := HeartbeatInterval}, _, _, State = #ws_conn_state{reconnect = Reconnect}) ->
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
handle_dispatch('READY', #{resume_gateway_url := ResumeGatewayUrl, session_id := SessionId}, State) ->
    ?DEBUG("Using resume_gateway_url: ~p and session_id: ~p", [ResumeGatewayUrl, SessionId]),
    State#ws_conn_state{resume_gateway_url = binary_to_list(binary:replace(ResumeGatewayUrl, <<"wss://">>, <<"">>)), session_id = SessionId};
handle_dispatch(_, _, State) ->
    State.

maybe_send_intents(resume) ->
    ok;
maybe_send_intents(_) ->
    dispatcher:send(intents:generate_intents_message()).
