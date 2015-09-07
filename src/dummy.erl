-module(dummy).
-export([start/0, stop/0]).

start() ->
  application:ensure_all_started(dummy).

stop() ->
  application:stop(dummy).