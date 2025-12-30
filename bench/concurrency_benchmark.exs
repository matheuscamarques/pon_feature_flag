defmodule PonFeatureFlag.ConcurrencyBenchmark do
  alias PonFeatureFlag.{FlagWatcher, PaymentProcessor, TraditionalProcessor}

  @num_workers 50
  @calls_per_worker 10000

  defp worker_loop(fun, calls) do
    for _ <- 1..calls do
      fun.(123)
    end

    :ok
  end

  defp set_flag_state({:dynamic, value}), do: FlagWatcher.sync_update_flag(value)
  defp set_flag_state({:traditional, value}), do: Application.put_env(:pon_feature_flag, :new_gateway_enabled, value)

  defp run_work(type) do
    target_fun =
      case type do
        :dynamic -> &PaymentProcessor.process/1
        :traditional -> &TraditionalProcessor.process/1
      end

    workers =
      for _ <- 1..@num_workers do
        Task.async(fn -> worker_loop(target_fun, @calls_per_worker) end)
      end

    Task.await_many(workers, 60_000)
  end

  def run do
    # Start the application
    Mix.Task.run("app.start")

    IO.puts("--- Running Concurrency Benchmark ---")
    IO.puts("  Workers: #{@num_workers}")
    IO.puts("  Calls per worker: #{@calls_per_worker}")
    IO.puts("  Total calls per run: #{@num_workers * @calls_per_worker}")
    IO.puts("----------------------------------------")

    # --- Benchmarking with Feature Flags ON ---
    IO.puts("\n--- Benchmarking with Feature Flags ON ---")
    set_flag_state({:dynamic, true})
    set_flag_state({:traditional, true})

    Benchee.run(
      %{
        "Dinamic PON (flag ON)"      => fn -> run_work(:dynamic) end,
        "Tradicional Ifs (flag ON)"  => fn -> run_work(:traditional) end
      },
      title: "Concurrency Benchmark (#{@num_workers} workers, static flag ON)",
      time: 10,
      warmup: 2,
      memory_time: 2
    )

    # --- Benchmarking with Feature Flags OFF ---
    IO.puts("\n--- Benchmarking with Feature Flags OFF ---")
    set_flag_state({:dynamic, false})
    set_flag_state({:traditional, false})

    Benchee.run(
      %{
        "Dinamic PON (flag OFF)"      => fn -> run_work(:dynamic) end,
        "Tradicional Ifs (flag OFF)"  => fn -> run_work(:traditional) end
      },
      title: "Concurrency Benchmark (#{@num_workers} workers, static flag OFF)",
      time: 10,
      warmup: 2,
      memory_time: 2
    )
  end
end

PonFeatureFlag.ConcurrencyBenchmark.run()
