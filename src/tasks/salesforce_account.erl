-module(salesforce_account).

-behaviour(poolmachine_task_behaviour).

-export([call/2, on_success/3, on_error/4, init/0]).

call([Field, Value], #{session_id := SessionId, server_url := Url}) ->
  {_, _, _, Accounts} = erlforce:soql_query(account_query(Field, Value), SessionId, Url),
  AccountsMap = transform_to_map(Accounts),
  {ok, save_accounts(AccountsMap)}.

on_success(Result, TaskRef, RespondTo) ->
  RespondTo ! {TaskRef, {success, Result}}.

on_error(Error, TaskRef, RespondTo, _Data) ->
  RespondTo ! {TaskRef, {error, Error}}.

init() ->
  {ok, SalesforceCredentials} = application:get_env(dummy, salesforce_credentials),
  [{sessionId, SessionId}, {serverUrl,Endpoint}] = apply(erlforce, login, SalesforceCredentials),
  {ok, #{session_id => SessionId,
         server_url => Endpoint}}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
account_query(Field, Value) ->
  "select Id, Name, Company_Legal_Name__c, GUID__c from Account where " ++ Field ++ "= '" ++ Value ++ "'".

transform_to_map(SalesforceAccounts) ->
  [account_to_map(Account) || Account <- SalesforceAccounts].

account_to_map(AccountResult) ->
  [{list_to_binary(Key), list_to_binary(Value)} || {Key, _, Value} <- AccountResult].

save_accounts(AccountsMap) ->
  DBTask = poolmachine:new_task(#{module => db,
                                  args => {insert, fun(Connection) -> epgsql:squery(Connection, "insert into test (data) values ('something')") end}}),
  {success, R} = poolmachine:run(postgresql, DBTask),
  R.


% dummy:start(),
% poolmachine:start_pool(postgresql, #{worker_init_function => fun() -> db:init() end}),
% DBTask = poolmachine:new_task(#{module => db, args => {insert, fun(Connection) -> epgsql:squery(Connection, "insert into test (data) values ('something')") end}}),
% poolmachine:run(postgresql, DBTask),
% poolmachine:start_pool(salesforce, #{worker_init_function => fun()-> salesforce_account:init() end}),
% Task = poolmachine:new_task(#{module => salesforce_account, args => ["Guid__c", "0000454b-c1d3-b3b7-fd65-916939c96cb3"]}).