defmodule Datastore do
  use GenServer
  require Logger
  @accounts "db/accounts.dets"
  @portfolios "db/portfolios.dets"
  ## 2 hours
  @dbs_backup_cycle 2 * 60 * 60 * 1000

  ##########################################################
  # Client API
  ##########################################################

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: :db)
    GenServer.call(pid, {:create_tables})
    {:ok, pid}
  end

  def get(pid, %AccountModel{} = a) do
    GenServer.call(pid, {:get, :account, a.account_number})
  end

  def get(pid, %PortfolioModel{} = p) do
    GenServer.call(pid, {:get, :portfolio, p.portfolio_number})
  end

  def get(pid, %AccountModel{} = a, timeout) do
    GenServer.call(pid, {:get, :account, a.account_number}, timeout)
  end

  def get(pid, %PortfolioModel{} = p, timeout) do
    GenServer.call(pid, {:get, :portfolio, p.portfolio_number}, timeout)
  end

  def put(pid, %AccountModel{} = a) do
    GenServer.call(pid, {:put, :account, a})
  end

  def put(pid, %PortfolioModel{} = p) do
    GenServer.call(pid, {:put, :portfolio, p})
  end

  def close(pid) do
    GenServer.call(pid, {:close})
  end

  def backup_store(pid) do
    GenServer.cast(pid, {:backup})
  end

  ##########################################################
  # Callbacks
  ##########################################################

  def init(args) do
    # In 2 hours
    Process.send_after(self(), :work, @dbs_backup_cycle)

    {:ok, args}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    close_dbs()
    backup_dbs()
    reopen_dbs()
    # Start the timer again
    # In 2 hours
    Process.send_after(self(), :work, @dbs_backup_cycle)
    {:noreply, state}
  end

  def handle_call({:create_tables}, _from, _) do
    a =
      case :dets.open_file(@accounts, type: :set) do
        {:error, reason} ->
          Logger.error(fn -> "Exited: #{inspect(reason)}" end)
          reason

        {:ok, a} ->
          a
      end

    p =
      case :dets.open_file(@portfolios, type: :set) do
        {:error, reason} ->
          Logger.error(fn -> "Exited: #{inspect(reason)}" end)
          reason

        {:ok, p} ->
          p
      end

    {:reply, a, p}
  end

  def handle_call({:close}, _from, _state) do
    {a, p} = close_dbs()
    {:reply, a, p}
  end

  def handle_call({:get, :account, account_number}, _from, state) do
    response =
      case :dets.lookup(@accounts, account_number) do
        {:error, reason} -> {:error, reason}
        [{key, value}] -> {key, value}
      end
    {:reply, response, state}
  end

  def handle_call({:get, :portfolio, portfolio_number}, _from, state) do
    response =
      case :dets.lookup(@portfolios, portfolio_number) do
        {:error, reason} ->
          {:error, reason}

        [{key, value}] ->
          {key, value}
          # other -> {other}
      end

    {:reply, response, state}
  end

  def handle_call({:put, :account, account}, _, _) do
    case :dets.insert_new(@accounts, {account.account_number, account}) do
      true -> {:reply, {:ok, account}, account}
      false -> {:reply, {:ok, account}, account}
      {:error, code} -> {:reply, {:error, code}, account}
    end
  end

  def handle_call({:put, :portfolio, portfolio}, _, _) do
    case :dets.insert_new(@portfolios, {portfolio.portfolio_number, portfolio}) do
      true -> {:reply, {:ok, portfolio}, portfolio}
      false -> {:reply, {:ok, portfolio}, portfolio}
      {:error, code} -> {:reply, {:error, code}, portfolio}
    end
  end

  def handle_cast({:backup}, state) do
    close_dbs()
    backup_dbs()
    reopen_dbs()
    {:noreply, state}
  end
  def handle_cast(request, state) do
    super(request, state)
  end
  ##########################################################
  # Helper functions
  ##########################################################

  defp close_dbs() do
    a = :dets.close(@accounts)
    p = :dets.close(@portfolios)
    {a, p}
  end

  defp backup_dbs() do
    {{y, mo, d}, {h, mi, s}} = :calendar.local_time()
    a = File.cp!(@accounts, "#{@accounts}.bak.#{y}_#{mo}_#{d}-#{h}_#{mi}_#{s}")
    p = File.cp!(@portfolios, "#{@portfolios}.bak.#{y}_#{mo}_#{d}-#{h}_#{mi}_#{s}")
    {a, p}
  end

  defp reopen_dbs() do
    a = :dets.open_file(@accounts, type: :set, ram_file: true)
    p = :dets.open_file(@portfolios, type: :set, ram_file: true)
    {a, p}
  end

  # defp get_ets_keys_lazy(table_name) do
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
