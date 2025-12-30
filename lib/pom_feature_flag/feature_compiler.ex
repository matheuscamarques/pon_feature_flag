defmodule PonFeatureFlag.FeatureCompiler do
  require Logger

  @doc """
  Recompila o módulo alvo injetando apenas o código necessário.

  ## Parâmetros
  - `feature_enabled?`: Booleano vindo da configuração (O Fato).
  """
  def recompile_module(feature_enabled?) do
    # 1. Definição da AST do Módulo completo.
    # O 'if' aqui é executado apenas UMA VEZ, durante a recompilação.
    # O código resultante será um dos dois módulos abaixo.
    module_ast =
      if feature_enabled? do
        quote do
          defmodule PonFeatureFlag.PaymentProcessor do
            require Logger
            def process(amount) do
              # Logger.info("Executando Fluxo V2 (Otimizado)")
              {:new, amount}
            end
          end
        end
      else
        quote do
          defmodule PonFeatureFlag.PaymentProcessor do
            require Logger
            def process(amount) do
              # Logger.info("Executando Fluxo V1 (Legado)")
              {:legacy, amount}
            end
          end
        end
      end

    # 2. Gerenciamento do Code Server (Mitigação de Riscos)
    # Purge suave para remover referências antigas e evitar vazamento de memória.
    :code.purge(PonFeatureFlag.PaymentProcessor)

    # Se o módulo já existe, ele é marcado como 'old' e o novo assume como 'current'.
    # Code.compile_quoted retorna
    [{module, binary}] = Code.compile_quoted(module_ast)

    # 3. Carregamento atômico do binário na VM
    {:module, ^module} = :code.load_binary(module, ~c"nofile", binary)

    # Logger.info("Módulo #{inspect(module)} recompilado. Feature Ativa? #{feature_enabled?}")
    {:ok, module}
  end
end
