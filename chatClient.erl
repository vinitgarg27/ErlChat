%% @doc Chat client implementation
-module(chatClient).
-export([connect/1, connect/2, disconnect/1, who_is_here/1, message/2]).

-spec connect(Host::string(), Name::string()) -> pid().
%% @doc connect to remote node with client name and return its Pid
connect(Host, Name) ->
	io:format('Remote host: ~p.~n', [Host]),
	ServerPid = rpc:call(Host, chatServer, find, []),
	io:format('Remote server: ~p.~n', [ServerPid]),
	put(chatServer, ServerPid),
	connect_to(ServerPid, Name).

-spec connect(Name::string()) -> pid().
%% @doc connect to local node with client name and return its Pid
connect(Name) ->
	ServerPid = whereis(chatServer),
	connect_to(ServerPid, Name).

connect_to(undefined, _) ->
	io:format('Can\'t find server.~n'),
	undefined;

connect_to(ServerPid, Name) ->
	io:format('Connect to ~p.~n', [ServerPid]),
	put(chatServer, ServerPid),
	ClientPid = spawn(fun loop/0),
	ServerPid ! {ClientPid, {login, Name}},
	ClientPid.

-spec who_is_here(Pid::pid()) -> any().
%% @doc retrive current logged users for client with Pid
who_is_here(Pid) ->
	server_ask(Pid, who).

-spec message(Pid::pid(), Message::any()) -> any().
%% @doc send any message to all logged clients from client with Pid
message(Pid, Message) ->
	server_ask(Pid, {message, Message}).

-spec disconnect(Pid::pid()) -> any().
%% @doc disconnect from server for client with Pid
disconnect(Pid) ->
	server_ask(Pid, leave).

loop() ->
	receive
		{_, welcome} ->
			io:format('~p: You are welcome!~n', [self()]),
			loop();
		{_, {names, Names}} ->
			io:format('~p: Clients here: ~p.~n', [self(), Names]),
			loop();
		{_, {message, From, Message}} ->
			io:format('~p: ~p: ~p~n', [self(), From, Message]),
			loop();
		{_, exit} ->
			io:format('~p: Client disconnected.~n', [self()]),
			exit(normal);
		_ ->
			exit(error)
	end.

server_ask(Pid, What) ->
	ServerPid = get(chatServer),
	ServerPid ! {Pid, What}.
