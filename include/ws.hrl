% State of the discord_ws_conn gen_server
-record(ws_conn_state, {
    bot_settings,
    conn_pid,
    stream_ref,
    resume_gateway_url,
    session_id,
    sequence_number = 0,
    reconnect,
    reconnect_attempts = 0,
    max_reconnect_attempts = 10
}).
