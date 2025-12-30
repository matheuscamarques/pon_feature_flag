defmodule PonFeatureFlag.TraditionalProcessor do
  def process(amount) do
    if Application.get_env(:pon_feature_flag, :new_gateway_enabled) do
      # In a real scenario, this would call the new processor.
      # To make the benchmark fair, we inline the logic.
      {:new, amount}
    else
      # In a real scenario, this would call the legacy processor.
      {:legacy, amount}
    end
  end
end
