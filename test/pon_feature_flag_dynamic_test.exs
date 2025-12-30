defmodule PonFeatureFlagDynamicTest do
  use ExUnit.Case, async: false
  alias PonFeatureFlag.{PaymentProcessor, FlagWatcher}

  setup do
    # Ensure the code is compiled with the default (false)
    FlagWatcher.sync_update_flag(false)
    :ok
  end

  test "PaymentProcessor starts with legacy implementation" do
    assert PaymentProcessor.process(100) == {:legacy, 100}
  end

  test "updating flag to true recompiles module to use new implementation" do
    # Initial state set by setup
    assert PaymentProcessor.process(100) == {:legacy, 100}

    # Update flag to enable new feature
    FlagWatcher.sync_update_flag(true)

    # Now it should use the new processor
    assert PaymentProcessor.process(200) == {:new, 200}
  end

  test "updating flag back to false recompiles module to use legacy implementation" do
    # Enable the new feature first
    FlagWatcher.sync_update_flag(true)
    assert PaymentProcessor.process(100) == {:new, 100}

    # Update flag to disable new feature
    FlagWatcher.sync_update_flag(false)

    # Now it should revert to the legacy processor
    assert PaymentProcessor.process(200) == {:legacy, 200}
  end
end
