-module(db).

-behaviour(poolmachine_task_behaviour).

-export([call/2, on_success/3, on_error/4]).

-export([init/0]).

call({insert, InsertFun}, Connection) ->
  InsertFun(Connection).

on_success(Result, TaskRef, RespondTo) ->
  RespondTo ! {TaskRef, {success, Result}}.

on_error(Error, TaskRef, RespondTo, _Data) ->
  RespondTo ! {TaskRef, {error, Error}}.

init() ->
  epgsql:connect("localhost", "test", "", [{database, "test"}]).