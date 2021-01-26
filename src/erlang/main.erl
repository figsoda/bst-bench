-module(main).

-export([start/0]).

start() ->
  io:format("~B~n", [
    gb_sets:size(
      lists:foldl(
        fun(X, Set) -> gb_sets:add(X, Set) end,
        gb_sets:new(),
        lists:seq(0, 999999)
      )
    )
  ]),
  halt().
