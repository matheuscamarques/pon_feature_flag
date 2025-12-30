defmodule PonFeatureFlag.FlagWatcher do
  use GenServer
  require Logger

  # Nome do processo para fácil acesso
  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    # Estado inicial: busca a configuração ao iniciar e compila a primeira versão.
    initial_config = fetch_config_from_source()
    PonFeatureFlag.FeatureCompiler.recompile_module(initial_config)

    # Simula inscrição em um canal de notificações (ex: Phoenix PubSub, PostgreSQL Notify)
    # PubSub.subscribe(:config_changes)

    {:ok, initial_config}
  end

  # Interface pública para simular uma mudança de flag (O evento externo)
  def update_flag(new_value) do
    GenServer.cast(__MODULE__, {:update_flag, new_value})
  end

  # Synchronous version for testing
  def sync_update_flag(new_value) do
    GenServer.call(__MODULE__, {:update_flag, new_value})
  end

  # Callback PON: Recebe Notificação -> Avalia -> Instiga Ação
  def handle_cast({:update_flag, new_value}, current_value) do
    if new_value != current_value do
      # Logger.notice("Detectada mudança de configuração. Iniciando recompilação reativa...")

      # AÇÃO: Recompilação do código dependente
      PonFeatureFlag.FeatureCompiler.recompile_module(new_value)

      {:noreply, new_value}
    else
      # Redundância Temporal evitada: Se o valor é igual, nada é feito.
      {:noreply, current_value}
    end
  end

  def handle_call({:update_flag, new_value}, _from, current_value) do
    if new_value != current_value do
      # Logger.notice("Detectada mudança de configuração. Iniciando recompilação reativa...")

      # AÇÃO: Recompilação do código dependente
      PonFeatureFlag.FeatureCompiler.recompile_module(new_value)

      {:reply, :ok, new_value}
    else
      # Redundância Temporal evitada: Se o valor é igual, nada é feito.
      {:reply, :ok, current_value}
    end
  end

  defp fetch_config_from_source, do: false # Default simulado
end
