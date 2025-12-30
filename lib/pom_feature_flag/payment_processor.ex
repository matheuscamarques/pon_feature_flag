defmodule PonFeatureFlag.PaymentProcessor do
  def process(amount) do
    PonFeatureFlag.LegacyPaymentProcessor.process(amount)
  end
end
