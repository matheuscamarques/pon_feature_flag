defmodule PonFeatureFlag.LegacyPaymentProcessor do
  def process(amount) do
    {:legacy, amount}
  end
end
