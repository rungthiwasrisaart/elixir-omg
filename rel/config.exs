# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  # This sets the default environment used by `mix release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set(dev_mode: false)
  set(include_erts: true)
  set(cookie: :dev)
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :prod)
end

release :watcher do
  set(version: current_version(:omg_watcher))
  set(vm_args: "rel/vm.args")

  set(
    applications: [
      :runtime_tools,
      omg_watcher: :permanent,
      omg: :permanent,
      omg_status: :permanent,
      omg_db: :permanent,
      omg_eth: :permanent
    ]
  )

  set(
    config_providers: [
      {OMG.Watcher.ReleaseTasks.InitContract, ["${RELEASE_ROOT_DIR}/config/config.exs"]}
    ]
  )

  set(
    commands: [
      init_pg_db: "rel/commands/watcher/init_pg_db.sh",
      init_kv_db: "rel/commands/watcher/init_kv_db.sh"
    ]
  )
end

release :child_chain do
  set(version: current_version(:omg_child_chain))
  set(vm_args: "rel/vm.args")

  set(
    applications: [
      :runtime_tools,
      omg_child_chain: :permanent,
      omg: :permanent,
      omg_status: :permanent,
      omg_db: :permanent,
      omg_eth: :permanent,
      omg_rpc: :permanent
    ]
  )

  set(
    config_providers: [
      {OMG.ChildChain.ReleaseTasks.InitContract, ["${RELEASE_ROOT_DIR}/config/config.exs"]}
    ]
  )

  set(
    commands: [
      init_kv_db: "rel/commands/child_chain/init_kv_db.sh"
    ]
  )
end
