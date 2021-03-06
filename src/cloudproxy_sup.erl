%% @author Marcel Neuhausler
%% @copyright 2012 Marcel Neuhausler
%%
%%    Licensed under the Apache License, Version 2.0 (the "License");
%%    you may not use this file except in compliance with the License.
%%    You may obtain a copy of the License at
%%
%%        http://www.apache.org/licenses/LICENSE-2.0
%%
%%    Unless required by applicable law or agreed to in writing, software
%%    distributed under the License is distributed on an "AS IS" BASIS,
%%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%    See the License for the specific language governing permissions and
%%    limitations under the License.


%% @doc Supervisor for the cloudproxy application.

-module(cloudproxy_sup).
-author('Marcel Neuhausler').

-behaviour(supervisor).

%% External exports
-export([start_link/0, upgrade/0]).

%% supervisor callbacks
-export([init/1]).

%% @spec start_link() -> ServerRet
%% @doc API for starting the supervisor.
start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @spec upgrade() -> ok
%% @doc Add processes if necessary.
upgrade() ->
	{ok, {_, Specs}} = init([]),

	Old = sets:from_list([Name || {Name, _, _, _} <- supervisor:which_children(?MODULE)]),
	New = sets:from_list([Name || {Name, _, _, _, _, _} <- Specs]),
	Kill = sets:subtract(Old, New),

	sets:fold(
		fun (Id, ok) ->
			supervisor:terminate_child(?MODULE, Id),
			supervisor:delete_child(?MODULE, Id),
			ok
		end,
		ok,
		Kill),

	[supervisor:start_child(?MODULE, Spec) || Spec <- Specs],
	ok.

%% @spec init([]) -> SupervisorTree
%% @doc supervisor callback.
init([]) ->
	{ok, Dispatch}     = file:consult(filename:join([filename:dirname(code:which(?MODULE)), "..", "priv", "dispatch.conf"])),
	{ok, Config}       = file:consult(filename:join([filename:dirname(code:which(?MODULE)), "..", "priv", "cloudproxy.conf"])),
	{ok, Port}         = get_option(port, Config),
	{ok, LogDir}       = get_option(log_dir, Config),
	{ok, PidFile}      = get_option(pid_file, Config),
	{ok, LogAttack}    = get_option(log_attack, Config),
	{ok, AttackGateway}= get_option(attack_gateway, Config),

	filelib:ensure_dir(LogDir),

	ok = file:write_file(PidFile, os:getpid()),

	WebConfig = [
		{ip, "0.0.0.0"},
		{port, Port},
		{log_dir, LogDir},
		{dispatch, Dispatch},
		{error_handler, cloudproxy_error_handler}
	],

	StateServerConfig = [
		{log_attack,     LogAttack},
		{attack_gateway, AttackGateway}
	], 

	StateServer =
	{
		cloudproxy_stateserver,
		{cloudproxy_stateserver, start, [StateServerConfig]},
		permanent,
		5000,
		worker,
		[]
	},
	
	WebServer =
	{
		webmachine_mochiweb,
		{webmachine_mochiweb, start, [WebConfig]},
		permanent,
		5000,
		worker,
		[mochiweb_socket_server, cloudproxy_stateserver]
	},

	Processes = [WebServer, StateServer],
	{ok, { {one_for_all, 10, 10}, Processes} }.


%% Utils

get_option(Option, Options) ->
	case lists:keyfind(Option, 1, Options) of
		false -> {ok, foo};
		{Option, Value} -> {ok, Value}
	end.

