# Copyright 2019-2020 OmiseGO Pte Ltd
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

defmodule OMG.Eth.ReleaseTasks.SetTenderlyFallbackCallDataProviderTest do
  use ExUnit.Case, async: false
  alias OMG.Eth.ReleaseTasks.SetTenderlyFallbackCallDataProvider

  @app :omg_eth
  @project_url "http://tenderly.project.url"
  @access_key "accesskey"
  @network_id "1"

  test "config is set from the env vars" do
    :ok = System.put_env("TENDERLY_PROJECT_URL", @project_url)
    :ok = System.put_env("TENDERLY_ACCESS_KEY", @access_key)
    :ok = System.put_env("TENDERLY_NETWORK_ID", @network_id)

    config =
      []
      |> SetTenderlyFallbackCallDataProvider.load([])
      |> Keyword.fetch!(@app)
      |> Keyword.fetch!(OMG.Eth.Tenderly.Client)

    assert Keyword.fetch!(config, :tenderly_project_url) == @project_url
    assert Keyword.fetch!(config, :access_key) == @access_key
    assert Keyword.fetch!(config, :network_id) == @network_id

    cleanup_env_vars()
  end

  test "default config is used when the env vars are not set" do
    cleanup_env_vars()
    app_default_config = Application.get_env(@app, OMG.Eth.Tenderly.Client)

    config =
      []
      |> SetTenderlyFallbackCallDataProvider.load([])
      |> Keyword.fetch!(@app)
      |> Keyword.fetch!(OMG.Eth.Tenderly.Client)

    assert config == app_default_config
  end

  test "does not fail when env vars are not set and default config is not present" do
    # if fallback call data provider is not set, that's fine
    # crash is expected at runtime, as watcher and childchain won't be able to pass through unrecognized call data
    cleanup_env_vars()
    app_default_config = Application.get_env(@app, OMG.Eth.Tenderly.Client)
    :ok = Application.delete_env(@app, OMG.Eth.Tenderly.Client)

    config =
      []
      |> SetTenderlyFallbackCallDataProvider.load([])
      |> Keyword.fetch!(@app)
      |> Keyword.fetch!(OMG.Eth.Tenderly.Client)

    assert config == [tenderly_project_url: nil, access_key: nil, network_id: nil]
    :ok = Application.put_env(@app, OMG.ETH.Tenderly.Client, app_default_config)
  end

  defp cleanup_env_vars() do
    :ok = System.delete_env("TENDERLY_PROJECT_URL")
    :ok = System.delete_env("TENDERLY_ACCESS_KEY")
    :ok = System.delete_env("TENDERLY_NETWORK_ID")
  end
end
