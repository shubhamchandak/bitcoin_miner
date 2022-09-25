-module(server).
-compile(export_all).

start(InitString, K, WorkerCount) -> 
    spawn(server, startMining, [InitString, K, WorkerCount]).

start(InitString, K, WorkerCount, Node) -> 
    spawn(Node, server, startMining, [InitString, K, WorkerCount]).
 
loop(_InitString, _K, 0) -> io:format("Exit~n");

loop(InitString, K, CurrWorkerCount) ->
    receive
        {Client, {BitcoinStr, HashValue, found}} -> 
            Client ! {kill},
            io:format("pid: ~p, bitcoin: ~p, hash_value: ~p~n", [Client, BitcoinStr, HashValue]);
        {Client, {not_found}} -> 
            io:format("not found on ~p~n", [Client])
    end,
    loop(InitString, K, CurrWorkerCount-1).

startMining(InitString, K, WorkerCount) -> 
    statistics(runtime),
    statistics(wall_clock),
    Pids = go(WorkerCount, []),
    do_work(Pids, {InitString, K}),
    loop(InitString, K, WorkerCount),
    {_, Time1} = statistics(runtime),
    {_, Time2} = statistics(wall_clock),
    io:format("CPU time = ~p microseconds Real Time= ~p microseconds~n",[Time1 * 1000, Time2 * 1000]).


go(0, Pids) ->
    io:format("All workers have been started.~n"),
    Pids;
go(N, Pids) ->
    Pid = spawn(worker, worker, [self()]),
    %io:format("~p~n", [Pid]),
    go(N-1, [Pid|Pids]).


do_work([Pid|Pids], Data) ->
    Pid ! {self(), Data},
    do_work(Pids, Data);
do_work([], _Data) ->
    io:format("All workers have been sent their work.~n").