defmodule AccountTest do
  use ExUnit.Case
  require ReceivableModel
  doctest DemoElixir.Application
  # @accounts "db/accounts.dets"

  setup_all do
    IO.puts("This is a setup callback for #{inspect(self())}")

    on_exit(fn ->
      IO.puts("This is invoked once the test is done. Process: #{inspect(self())}")

      Datastore.close(:db)
    end)
  end

  test "Account can be created" do
    name = String.to_atom("Testing")
    account = %AccountModel{account_number: name}
    {:ok, name} = GenServer.start_link(Account, account, name: {:global, name})

    {:ok, newstate} = Account.create(name, account)
    {:ok, ^newstate} = Account.get_state(name)
    account_number = newstate.account_number
    assert :Testing = account_number
  end

  test "Account can be assessed receivable" do
    name = String.to_atom("Testing")
    account = %AccountModel{account_number: name}
    {:ok, name} = GenServer.start_link(Account, account, name: {:global, name})

    receivable = %ReceivableModel{type: "DuesTest", amount: 100.00}
    {:ok, newstate} = Account.assess_receivable(name, receivable)
    {:ok, ^newstate} = Account.get_state(name)
    current_balance = newstate.current_balance
    assert 100.00 = current_balance
  end


  #   get_dets_keys_lazy(@accounts)
  #     |> Stream.map( &GenServer.start_link( Account, &1, name: name(&1) ))
  #     |> Stream.run

  #     assert true
  # end

  ##########################################################
  # Helper functions
  ##########################################################

  # defp get_dets_keys_lazy(table_name) do
  #   eot = :"$end_of_table"

  #   Stream.resource(
  #     fn -> [] end,
  #     fn acc ->
  #       case acc do
  #         [] ->
  #           case :dets.first(table_name) do
  #             ^eot -> {:halt, acc}
  #             first_key -> {[first_key], first_key}
  #           end

  #         acc ->
  #           case :dets.next(table_name, acc) do
  #             ^eot -> {:halt, acc}
  #             next_key -> {[next_key], next_key}
  #           end
  #       end
  #     end,
  #     fn acc -> acc end
  #   )
  # end
end
