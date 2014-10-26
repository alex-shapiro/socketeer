defmodule WebSocketHandler do
  @behaviour :cowboy_http_handler
  @behaviour :cowboy_websocket_handler


  ## This is the part where we handle our WebSocket protocols

  require Record
  Record.defrecord :state, handler: nil, handler_state: nil

  def init({_any, :http}, req, _opts) do
    { upgrade, req } = :cowboy_req.header("upgrade", req)
    case String.downcase(upgrade) do
      "websocket" -> { :upgrade, :protocol, :cowboy_websocket }
      _ -> not_implemented(req)
    end
  end

  def websocket_init(_any, req, _opts) do
    # Select a handler based on the WebSocket sub-protocol
    { headers, _ } = :cowboy_req.headers(req)
    { _ , protocol } = List.keyfind headers, "sec-websocket-protocol", 0
    handler = case protocol do
      "dumb-increment-protocol" -> DumbIncrementHandler
      "umtp-protocol" -> UmtpHandler
    end

    # Init selected handler
    case handler.init(_any, req) do
      {:ok, req, state} ->
        req = :cowboy_req.compact req
        req = :cowboy_req.set_resp_header("sec-websocket-protocol", protocol, req)
        {:ok, req, state(handler: handler, handler_state: state), :hibernate}

      {:shutdown, req, _state} ->
        {:shutdown, req}
    end
  end

  # Dispatch generic message to the handler
  def websocket_handle({:text, msg}, req, state(handler: handler, handler_state: handler_state)=state) do
    case handler.stream(msg, req, handler_state) do
      {:ok, req, new_state} ->
        {:ok, req, state(state, handler_state: new_state), :hibernate}

      {:reply, reply, req, new_state} ->
        {:reply, {:text, reply}, req, state(state, handler_state: new_state), :hibernate}
    end
  end

  # Default case
  def websocket_handle(_any, req, state) do
    {:ok, req, state, :hibernate}
  end

  # Various service messages
  def websocket_info(info, req, state(handler: handler, handler_state: handler_state)=state) do
    case handler.info(info, req, handler_state) do
      {:ok, req, new_state} ->
        format_ok req, state(state, handler_state: new_state)

      {:reply, reply, req, new_state} ->
        format_reply req, reply, state(state, handler_state: new_state)
    end
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end


  ## This is the HTTP part of the handler. It will only start up
  ## properly, if the request is asking to upgrade the protocol to
  ## WebSocket

  defp not_implemented(req) do
    { :ok, req } = :cowboy_req.reply(501, [], [], req)
    { :shutdown, req, :undefined }
  end

  def handle(req, _state) do
    not_implemented req
  end

  def terminate(_reason, _req, _state) do
    :ok
  end


  ## Private API

  defp format_ok(req, state) do
    {:ok, req, state, :hibernate}
  end

  defp format_reply(req, reply, state) do
    {:reply, {:text, reply}, req, state, :hibernate}
  end
end
