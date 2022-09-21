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

mine(Server, InitString, K) ->
    NewInitString = InitString ++ binary_to_list(base64:encode(crypto:strong_rand_bytes(6))),
    HashValue = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,NewInitString))]),
    IsValid = isValid(HashValue, K),
    if
        IsValid -> Server ! {self(), {NewInitString, found}};
        true -> mine(Server, InitString, K)
    end.

isValid(HashValue, K) ->
    Ch = string:substr(HashValue, 1, 1),
    if
        K < 0 -> true;
        Ch =/= "0" -> false;
        true -> isValid(string:substr(HashValue, 2), K-1)
    end.


