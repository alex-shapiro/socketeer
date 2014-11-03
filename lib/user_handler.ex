defmodule UserHandler do
  defstruct username: "", state: :new

  def init(_any, req) do
    {:ok, req, %UserHandler{}}
  end

  def stream("username: " <> username, req, state) do
    case register_user(String.strip(username)) do
      :registered -> {:reply, "220 ready to send", req, %UserHandler{username: username, state: :ready_to_send}}
      :already_taken -> {:reply, "400 name currently taken", req, state}
      :invalid -> {:reply, "500 invalid name", req, state}
    end
  end

  def stream(message, req, state) do
    if state.state != :ready_to_send do
      {:reply, "400 incorrect state", req, state}
    else
      case send_message(String.strip(message), state.username) do
        :sent ->
          IO.puts "200 sent"
          {:reply, "200 sent", req, state}
        :invalid_recipient ->
          IO.puts "400 recipient not online"
          {:reply, "400 recipient not online", req, state}
        :empty_message ->
          IO.puts "500 empty message"
          {:reply, "500 empty message", req, state}
      end
    end
  end

  def info({:message, sender, message}, req, state) do
    json = Poison.encode! %{sender: sender, message: message}
    IO.puts json
    {:reply, json, req, state}
  end

  def info(info, req, state) do
    IO.puts info
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp register_user(username) do
    if username == "" do
      :invalid
    else
      self_pid = self()
      case :gproc.reg_or_locate {:n, :l, username} do
        {^self_pid,_} -> :registered
        _ -> :already_taken
      end
    end
  end

  defp send_message(message, sender) do
    %{"recipient" => recipient, "message" => message} = Poison.Parser.parse!(message)
    if message == "" do
      :empty_message
    else
      case :gproc.lookup_pids {:n, :l, recipient} do
        [pid|_] ->
          send(pid, {:message, sender, message})
          :sent
        [] -> :invalid_recipient
      end
    end
  end

end
