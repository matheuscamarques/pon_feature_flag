# Make sure the application is started
Mix.Task.run("app.start")

# Set up the initial state for both processors
# For the dynamic one, we compile it. Let's test the "new feature" path.
PonFeatureFlag.FlagWatcher.sync_update_flag(true)

# For the traditional one, we set the app env.
Application.put_env(:pon_feature_flag, :new_gateway_enabled, true)

IO.puts("--- Benchmarking Hot Path (feature enabled) ---")

Benchee.run(
  %{
    "Dynamic (PON-style)" => fn amount -> PonFeatureFlag.PaymentProcessor.process(amount) end,
    "Traditional (if + App env)" => fn amount -> PonFeatureFlag.TraditionalProcessor.process(amount) end
  },
  inputs: %{
    "Integer" => 123
  },
  title: "Feature Flag Hot Path (Flag ON)",
  memory_time: 2
)

# --- Now, let's test the "feature disabled" path ---

# For the dynamic one, we recompile it.
PonFeatureFlag.FlagWatcher.sync_update_flag(false)

# For the traditional one, we set the app env.
Application.put_env(:pon_feature_flag, :new_gateway_enabled, false)

IO.puts("\n--- Benchmarking Hot Path (feature disabled) ---")

Benchee.run(
  %{
    "Dynamic (PON-style)" => fn amount -> PonFeatureFlag.PaymentProcessor.process(amount) end,
    "Traditional (if + App env)" => fn amount -> PonFeatureFlag.TraditionalProcessor.process(amount) end
  },
  inputs: %{
    "Integer" => 456
  },
  title: "Feature Flag Hot Path (Flag OFF)",
  memory_time: 2
)

# --- Now, let's benchmark the "cold path" (the flag flip itself) ---

IO.puts("\n--- Benchmarking Cold Path (the flag flip) ---")

Benchee.run(
  %{
    "Dynamic (PON-style) Flip ON" => fn -> PonFeatureFlag.FlagWatcher.sync_update_flag(true) end,
    "Traditional (App env) Flip ON" => fn -> Application.put_env(:pon_feature_flag, :new_gateway_enabled, true) end,
    "Dynamic (PON-style) Flip OFF" => fn -> PonFeatureFlag.FlagWatcher.sync_update_flag(false) end,
    "Traditional (App env) Flip OFF" => fn -> Application.put_env(:pon_feature_flag, :new_gateway_enabled, false) end
  },
  time: 100, # ms
  warmup: 10, # ms
  title: "Feature Flag Cold Path (Flag Flip Cost)",
  memory_time: 2
)
