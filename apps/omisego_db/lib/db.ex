defmodule OmiseGO.DB do
  @moduledoc """
  Our-types-aware port/adapter to the db backend.
  Call these functions to access the data stored in the database
  """

  ### Client (port)

  @server_name OmiseGO.DB.LevelDBServer

  def multi_update(db_updates, server_name \\ @server_name) do
    GenServer.call(server_name, {:multi_update, db_updates})
  end

  @spec blocks(block_to_fetch :: list()) :: {:ok, list()} | {:error, any}
  def blocks(blocks_to_fetch, server_name \\ @server_name) do
    GenServer.call(server_name, {:blocks, blocks_to_fetch})
  end

  def utxos(server_name \\ @server_name) do
    GenServer.call(server_name, {:utxos})
  end

  def block_hashes(block_numbers_to_fetch, server_name \\ @server_name) do
    GenServer.call(server_name, {:block_hashes, block_numbers_to_fetch})
  end

  def last_deposit_height(server_name \\ @server_name) do
    GenServer.call(server_name, :last_deposit_block_height)
  end

  def child_top_block_number(server_name \\ @server_name) do
    GenServer.call(server_name, :child_top_block_number)
  end

  def last_fast_exit_block_height(server_name \\ @server_name) do
    GenServer.call(server_name, :last_fast_exit_block_height)
  end

  def last_slow_exit_block_height(server_name \\ @server_name) do
    GenServer.call(server_name, :last_slow_exit_block_height)
  end

  def init do
    path = Application.get_env(:omisego_db, :leveldb_path)
    :ok = File.mkdir_p(path)

    if Enum.empty?(File.ls!(path)) do
      {:ok, started_apps} = Application.ensure_all_started(:omisego_db)
      :ok = OmiseGO.DB.multi_update([{:put, :last_deposit_block_height, 0}])
      :ok = OmiseGO.DB.multi_update([{:put, :last_fast_exit_block_height, 0}])
      :ok = OmiseGO.DB.multi_update([{:put, :last_slow_exit_block_height, 0}])
      :ok = OmiseGO.DB.multi_update([{:put, :child_top_block_number, 0}])
      started_apps |> Enum.reverse() |> Enum.each(fn app -> :ok = Application.stop(app) end)

      # TODO: possible source of flakiness is omisego_db not cleaning up fast enough? find a better solution
      Process.sleep(500)

      :ok
    else
      {:error, :folder_not_empty}
    end
  end
end
