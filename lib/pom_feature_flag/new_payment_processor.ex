defmodule PonFeatureFlag.NewPaymentProcessor do
  def process(amount) do
    {:new, amount}
  end
end
