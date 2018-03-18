defmodule DemoElixirTest do
  use ExUnit.Case
  doctest DemoElixir.Application
  @milliseconds (1000)
  @milliseconds_micro (1000 * @milliseconds)
  @seconds (60 * @milliseconds)
  @seconds_micro (60 * @milliseconds_micro)
  @minutes (60 * @seconds)
  @minutes_micro (60 * @seconds_micro)

  @timeout_period (10 * @minutes)
  @acceptable_period (10 * @minutes_micro)
  @number_of_accounts 120_000

  setup_all do
    IO.puts("This is a setup callback for #{inspect(self())}")
    IO.puts("seconds: #{@seconds} in milliseconds")
    IO.puts("minutes: #{@minutes} in milliseconds")
    IO.puts("timeout_period: #{@timeout_period} in milliseconds")
    IO.puts("acceptable_period: #{@acceptable_period} in microseconds")

    IO.puts(
      "Testing that dets storage of #{@number_of_accounts} accounts happens in under #{
        @acceptable_period / (@minutes_micro)
      } minutes"
    )

    1..@number_of_accounts
    |> Enum.map(&build(&1))
    |> Enum.map(&Datastore.put(:db, &1))

    on_exit(fn ->
      IO.puts("This is invoked once the test is done. Process: #{inspect(self())}")
      #IO.puts("Deleting file accounts.dets")
      #File.rm!("accounts.dets")
      #IO.puts("Deleting file portfolios.dets")
      #File.rm!("portfolios.dets")
     Datastore.close(:db)
    end)
  end

  @tag timeout: @timeout_period
  test "account stored within acceptable time of #{@acceptable_period} ms" do
    {time, _} = :timer.tc(fn -> wait_for_store(@number_of_accounts) end, [])
    report_time(time)
    assert time <= @acceptable_period
  end

  @tag timeout: @timeout_period
  test "last account retrieved" do
    {time, [{account_number, _} | _]} =
      :timer.tc(fn -> wait_for_store(@number_of_accounts) end, [])
      report_time(time)
    assert @number_of_accounts = account_number
  end

  @tag timeout: @timeout_period
  test "All keys were retrieved successfully" do
    list =
      1..@number_of_accounts
      |> Enum.map(&build(&1))
      |> Enum.map(&Datastore.get(:db, &1))
      |> Enum.map(&extract_key(&1))

    records = length(list)
    assert @number_of_accounts = records
  end

  ##########################################################
  # Helper functions
  ##########################################################

  defp extract_key([{key, %AccountModel{account_number: key}} | _] = _result) do
    key
  end

  defp build(num) do
    %AccountModel{account_number: num}
  end

  defp wait_for_store(key) do
    a = %AccountModel{account_number: key}
    Datastore.get(:db, a, :infinity)
  end

  defp report_time(time) do
    minutes = Float.round((time / (@seconds_micro)), 2)

    if time > @milliseconds_micro do
      IO.puts(
        "It took #{minutes} minutes (#{time}µs) to store #{@number_of_accounts} accounts to disk."
      )
    else
      IO.puts(
        "It took (#{time}µs) to retrieve an account from disk."
      )
    end
  end
end
