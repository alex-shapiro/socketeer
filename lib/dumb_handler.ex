defmodule DumbIncrementHandler do

  require Record
  Record.defrecordp :state, counter: 0

  def init(_any, req) do
    :timer.send_interval 50, :tick
    {:ok, req, state()}
  end

  def stream("reset\n", req, _state) do
    {:ok, req, state(counter: 0)}
  end

  # Received timer event
  def info(:tick, req, state(counter: counter)) do
    {:reply,
      to_string(counter),
      req,
      state(counter: counter+1)}
  end

  def info(_info, req, state) do
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end

