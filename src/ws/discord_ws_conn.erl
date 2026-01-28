-module(discord_ws_conn).
-behaviour(gen_server).

%% API.
-export([start_link/0]).

%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

-export([
    get_ws/0,
    get_spec/0,
    reconnect/2
]).

%% Macros

-include("ws.hrl").
-include("logging.hrl").
-include("discord_api_types.hrl").
-include("macros.hrl").

%% API.

get_ws() ->
    gen_server:call(?MODULE, get_ws, 1000).

get_spec() -> #{
    id => ?MODULE,
    start => {?MODULE, start_link, []},
    restart => permanent,
    type => worker,
    modules => [?MODULE]
}.

-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% gen_server.

init([]) ->
    {ok, BotSettings} = get_bot_settings(),
    ?DEBUG("Got bot settings: ~p", [BotSettings]),
    % Open the connection to the gateway
    #{<<"url">> := <<"wss://", GatewayUrl/binary>>} = BotSettings,
    {ok, ConnPid} = gun:open(binary_to_list(GatewayUrl), 443,
                            #{protocols => [http],
                              retry => 0,
                              transport => tls,
                              tls_opts => [{verify, verify_none}, {cacerts, certifi:cacerts()}],
                              http_opts => #{version => 'HTTP/1.1'}}),
    % Await the successfull connection
    {ok, http} = gun:await_up(ConnPid),
    % Upgrade to a websocket
    gun:ws_upgrade(ConnPid, "/?v=10&encoding=etf"),
    {ok, #ws_conn_state{bot_settings = BotSettings}}.

handle_call(get_ws, _From, State = #ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}) ->
    {reply, {ConnPid, StreamRef}, State};
handle_call(get_seq, _From, State = #ws_conn_state{sequence_number = Seq}) ->
    {reply, Seq, State};
handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({gun_ws, _ConnPid, _StreamRef, {binary, Data}}, State0) ->
    #{s := S, op := OP, d := D, t:= T} = binary_to_term(Data),
    State = discord_api_gateway_handler:handle_gateway_event(OP, D, S, T, State0),
    {noreply, State};
handle_info({gun_ws, ConnPid, StreamRef, {close, CloseCode, Reason}}, State0 = #ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}) ->
    ?DEBUG("Handling close code: ~p with reason: ~p", [CloseCode, Reason]),
    ReconnectMode =
        case lists:member(CloseCode, ?RECONNECT_CLOSE_CODES) of
            true -> resume;
            _    -> identify
        end,
    GenServerReturn = reconnect(ReconnectMode, State0),
    GenServerReturn;
handle_info({gun_ws, ConnPid, StreamRef, close}, State = #ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}) ->
    ?DEBUG("Got empty close code"),
    {noreply, State#ws_conn_state{reconnect = resume}};
handle_info({gun_upgrade, ConnPid, StreamRef, [<<"websocket">>], _Headers}, State = #ws_conn_state{reconnect = resume, session_id = SessionId, sequence_number = Seq}) ->
    dispatcher:send(#{?OP => ?RESUME, ?D => #{<<"token">> => list_to_binary(?BOT_TOKEN), <<"session_id">> => SessionId, <<"seq">> => Seq}}),
    {noreply, State#ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}};
handle_info({gun_upgrade, ConnPid, StreamRef, [<<"websocket">>], _Headers}, State) ->
    {noreply, State#ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}};
handle_info({gun_response, _ConnPid, _, _, Status, Headers}, State) ->
    {stop, {ws_upgrade_failed, Status, Headers}, State};
handle_info({gun_error, _ConnPid, _StreamRef, Reason}, State) ->
    {stop, {ws_upgrade_failed, Reason}, State};
handle_info({gun_down, ConnPid, ws, closed, [StreamRef]}, State0 = #ws_conn_state{conn_pid = ConnPid, stream_ref = StreamRef}) ->
    State = reconnect(resume, State0),
    {noreply, State};
handle_info({gun_down, ConnPid, ws, Reason, _}, State0 = #ws_conn_state{conn_pid = ConnPid}) ->
    ?DEBUG("Connection down with reason: ~p", [Reason]),
    State = reconnect(resume, State0),
    {noreply, State};
handle_info(reset_reconnect_attempts, State) ->
    %% Called after successful READY/RESUMED to reset the counter
    {noreply, State#ws_conn_state{reconnect_attempts = 0}};
handle_info(Info, State) ->
    ?DEBUG("Handle info: ~p", [Info]),
    ?DEBUG("With State: ~p", [State]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ==========================================================
%% Internal Functions
%% ==========================================================
reconnect(resume, State = #ws_conn_state{
    resume_gateway_url = ResumeGatewayUrl,
    conn_pid = OldConnPid,
    reconnect_attempts = Attempts,
    max_reconnect_attempts = MaxAttempts
}) when Attempts < MaxAttempts ->
    %% Calculate backoff delay: min(2^attempts * 1000, 60000) ms
    BackoffMs = min(trunc(math:pow(2, Attempts)) * 1000, 60000),
    ?INFO("Reconnecting (attempt ~p/~p) after ~p ms", [Attempts + 1, MaxAttempts, BackoffMs]),
    timer:sleep(BackoffMs),

    ?DEBUG("Closing ws connection"),
    catch gun:close(OldConnPid),

    %% Open the connection to the resume url gateway
    ?DEBUG("Opening new connection to ~s", [ResumeGatewayUrl]),
    case gun:open(ResumeGatewayUrl, 443,
                  #{protocols => [http],
                    retry => 0,
                    transport => tls,
                    tls_opts => [{verify, verify_none}, {cacerts, certifi:cacerts()}],
                    http_opts => #{version => 'HTTP/1.1'}}) of
        {ok, ConnPid} ->
            case gun:await_up(ConnPid, 10000) of
                {ok, http} ->
                    ?DEBUG("Upgrading connection to ws"),
                    gun:ws_upgrade(ConnPid, "/?v=10&encoding=etf"),
                    State#ws_conn_state{
                        conn_pid = ConnPid,
                        reconnect = resume,
                        reconnect_attempts = Attempts + 1
                    };
                {error, Reason} ->
                    ?ERROR("Failed to await gun up: ~p", [Reason]),
                    gun:close(ConnPid),
                    reconnect(resume, State#ws_conn_state{reconnect_attempts = Attempts + 1})
            end;
        {error, Reason} ->
            ?ERROR("Failed to open connection: ~p", [Reason]),
            reconnect(resume, State#ws_conn_state{reconnect_attempts = Attempts + 1})
    end;

reconnect(resume, #ws_conn_state{conn_pid = ConnPid, max_reconnect_attempts = MaxAttempts}) ->
    ?ERROR("Max reconnect attempts (~p) reached, giving up", [MaxAttempts]),
    catch gun:close(ConnPid),
    gen_server:stop(?MODULE, max_reconnect_attempts, 5000);

reconnect(identify, #ws_conn_state{conn_pid = ConnPid}) ->
    ?INFO("Reconnecting with fresh identify"),
    catch gun:close(ConnPid),
    gen_server:stop(?MODULE, disconnected, 5000).

get_bot_settings() ->
    % Make a http request to https://discord.com/api/v10/gateway/bot and get the bot settings
    BotToken = list_to_binary(?BOT_TOKEN),
    {ok, ConnPid} = gun:open("discord.com", 443,
                            #{protocols => [http],
                              retry => 0,
                              transport => tls,
                              tls_opts => [{verify, verify_none}, {cacerts, certifi:cacerts()}],
                              http_opts => #{version => 'HTTP/1.1'}}),

    {ok, http} = gun:await_up(ConnPid),
    StreamRef = gun:request(ConnPid, <<"GET">>, <<"/api/v10/gateway/bot">>,
                                  #{<<"Authorization">> => <<"Bot ", BotToken/binary>>,
                                    <<"User-Agent">> => <<"DiscordBot (+https://discord.com/developers/docs/topics/gateway#bot)">>,
                                    <<"Accept">> => <<"application/json">>}, []),

    case gun:await(ConnPid, StreamRef) of
        {response, fin, _, _} ->
            gun:close(ConnPid),
            {error, bot_options_not_found};
        {response, nofin, _, _} ->
            {ok, Body} = gun:await_body(ConnPid, StreamRef),
            gun:close(ConnPid),
            BotSettings = jsx:decode(Body),
            {ok, BotSettings}
    end.