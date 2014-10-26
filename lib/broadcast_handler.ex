defmodule BroadcastHandler do
  require Poison

  def init(_any, req) do
    subscribe
    {:ok, req, :fine}
  end

  def stream(msg, req, state) do
    broadcast msg
    {:ok, req, state}
  end

  def info({:chatroom, msg}, req, state) do
    {:reply, msg, req, state}
  end

  def info(_info, req, state) do
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  ## Private functions ##

  defp subscribe do
    :gproc.reg {:p, :l, :chatroom}
  end

  defp broadcast(msg) do
    :gproc.send {:p, :l, :chatroom},
                {:chatroom, msg}
  end

end


    # broadcast(msg)
    # %{"sender" => sender, "message" => message} = Poison.Parser.parse!(msg)
