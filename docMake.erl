-module(docMake).
-export([make/0]).

make() ->
	edoc:files(['chatServer.erl', 'chatClient.erl', 'chatStorage.erl'], [{dir, 'Docs'}]).
