# Copyright 2019-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule OMG.WatcherRPC.ReleaseTasks.SetTracer do
  @moduledoc false
  @behaviour Config.Provider
  alias OMG.WatcherRPC.Tracer
  require Logger

  @app :omg_watcher_rpc

  def init(args) do
    args
  end

  def load(config, args) do
    _ = on_load()
    adapter = Keyword.get(args, :system_adapter, System)
    _ = Process.put(:system_adapter, adapter)
    dd_disabled = get_dd_disabled()

    tracer_config =
      @app
      |> Application.get_env(Tracer)
      |> Keyword.put(:disabled?, dd_disabled)

    tracer_config =
      case dd_disabled do
        false ->
          app_env = get_app_env()
          Keyword.put(tracer_config, :env, app_env)

        true ->
          Keyword.put(tracer_config, :env, "")
      end

    Config.Reader.merge(config,
      omg_watcher_rpc: [{Tracer, tracer_config}],
      spandex_phoenix: [tracer: Tracer]
    )
  end

  defp get_dd_disabled() do
    dd_disabled = Application.get_env(@app, OMG.WatcherRPC.Tracer)[:disabled?]
    dd_disabled? = validate_bool(get_env("DD_DISABLED"), dd_disabled)

    _ = Logger.info("CONFIGURATION: App: #{@app} Key: DD_DISABLED Value: #{inspect(dd_disabled?)}.")
    dd_disabled?
  end

  defp get_app_env() do
    env = validate_string(get_env("APP_ENV"), Application.get_env(@app, OMG.WatcherRPC.Tracer)[:env])
    _ = Logger.info("CONFIGURATION: App: #{@app} Key: APP_ENV Value: #{inspect(env)}.")
    env
  end

  defp get_env(key) do
    Process.get(:system_adapter).get_env(key)
  end

  defp validate_bool(value, _default) when is_binary(value), do: to_bool(String.upcase(value))
  defp validate_bool(_, default), do: default

  defp to_bool("TRUE"), do: true
  defp to_bool("FALSE"), do: false
  defp to_bool(_), do: exit("DD_DISABLED either true or false.")

  defp validate_string(value, _default) when is_binary(value), do: value
  defp validate_string(_, default), do: default

  defp on_load() do
    _ = Application.ensure_all_started(:logger)
    Application.load(@app)
  end
end
