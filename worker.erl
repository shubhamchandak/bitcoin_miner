-module(worker).
-export([mine/3, worker/1]).

worker(From) ->
    receive
        {From, {InitString, K}} ->
            mine(From, InitString, K);
            {kill} -> exit(self(), kill);
        Other ->
            io:format("Error, received ~w.~n", [Other])
    end,
    worker(From).

mine(Server, InitString, K) -> mine(Server, InitString, K, 10000).
mine(Server, InitString, K, 0) -> Server ! {self(), {not_found}};
mine(Server, InitString, K, WorkUnits) ->
    NewInitString = InitString ++ binary_to_list(base64:encode(crypto:strong_rand_bytes(6))),
    HashValue = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,NewInitString))]),
    IsValid = isValid(HashValue, K),
    if
        IsValid -> Server ! {self(), {NewInitString, HashValue, found}};
        true -> mine(Server, InitString, K, WorkUnits-1)
    end.

isValid(HashValue, 0) -> true;
isValid(HashValue, K) ->
    Ch = string:substr(HashValue, 1, 1),
    if
        Ch =/= "0" -> false;
        true -> isValid(string:substr(HashValue, 2), K-1)
    end.


