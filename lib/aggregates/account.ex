defmodule Account do
  require Datastore
  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def create(pid, %AccountModel{} = a) do
    GenServer.call(pid, {:create, a})
  end

  def assess_receivable(pid, %ReceivableModel{} = r, timeout \\ 5000) do
    GenServer.call(pid, {:assess_receivable, r}, timeout)
  end

  def get_state(pid, timeout \\ 5000) do
    GenServer.call(pid, {:get_state}, timeout)
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, {:ok,state},state}
  end

  def handle_call({:assess_receivable, receivable}, _from, state) do
    {newbal, event} = apply_receivable(state, receivable)
    newevents = [event | state.events]
    newstate = %{state | current_balance: newbal}
    newstate = %{newstate | events: newevents}

    case Datastore.put(:db, newstate) do
      {:ok, saved} -> {:reply, {:ok, saved} , newstate}
      {_, error} -> {:reply, {:error, error} , state}
    end
  end

  def handle_call({:create, account},_, _) do
    {:ok,newstate}=Datastore.put(:db, account)
    ## account becomes state
    {:reply, {:ok,newstate},newstate}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  defp apply_receivable(%AccountModel{} = a, r) do
    # TODO: fancy business rules here
    amount = a.current_balance + r.amount

    event = %DomainEventModel{
      event: "Assessed a #{r.type} receivable #{r.amount}. The balance is: #{amount}"
    }

    {amount, event}
  end

  def init(%AccountModel{} = state) do
    {:ok, state}
  end
end
