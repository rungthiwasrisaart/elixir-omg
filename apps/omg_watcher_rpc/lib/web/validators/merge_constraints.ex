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

defmodule OMG.WatcherRPC.Web.Validator.MergeConstraints do
  @moduledoc """
  Validates `/transaction.merge` parameters
  """

  import OMG.Utils.HttpRPC.Validator.Base

  alias OMG.State.Transaction
  alias OMG.WatcherRPC.Web.Validator.Helpers

  require OMG.State.Transaction.Payment

  @max_inputs Transaction.Payment.max_inputs()

  defp get_constraints(params) do
    case params do
      %{"address" => _, "currency" => _} ->
        [
          {"address", [:address], :address},
          {"currency", [:currency], :currency}
        ]

      %{"utxos" => _} ->
        [{"utxos", [min_length: 2, max_length: @max_inputs, list: &validate_utxo/1], :utxos}]

      %{"utxo_positions" => _} ->
        [{"utxo_positions", [min_length: 2, max_length: @max_inputs, list: &to_utxo_pos/1], :utxo_positions}]

      _ ->
        {:error, :operation_bad_request}
    end
  end

  @doc """
  Parses and validates request body for `/transaction.merge`
  """
  @spec parse(map()) :: {:ok, map()} | Base.validation_error_t()
  def parse(params) do
    case get_constraints(params) do
      {:error, error} ->
        {:error, error}

      constraints ->
        validate_params(params, constraints)
    end
  end

  defp validate_params(params, constraints) do
    case Helpers.validate_constraints(params, constraints) do
      {:ok, result} -> {:ok, Map.new(result)}
      error -> error
    end
  end

  defp validate_utxo(utxo) do
    with {:ok, _blknum} <- expect(utxo, "blknum", :pos_integer),
         {:ok, _txindex} <- expect(utxo, "txindex", :pos_integer),
         {:ok, _oindex} <- expect(utxo, "oindex", :pos_integer),
         {:ok, _owner} <- expect(utxo, "owner", :address),
         {:ok, _currency} <- expect(utxo, "currency", :currency),
         {:ok, _amount} <- expect(utxo, "amount", :pos_integer) do
      {:ok, utxo}
    end
  end

  defp to_utxo_pos(utxo_pos_string) do
    expect(%{"utxo_pos" => utxo_pos_string}, "utxo_pos", :non_neg_integer)
  end
end
