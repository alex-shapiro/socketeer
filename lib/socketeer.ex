defmodule Socketeer do
  @behaviour :application

  def start(_type, _args) do
    dispatch = :cowboy_router.compile([
      {:_, [
        {'/', StaticHandler, []},
        {'/socketeer', WebSocketHandler, []}
      ]}
    ])

    :cowboy.start_http(
      :my_http_listener,
      100,
      [{:port, 8080}],
      [{:env, [{:dispatch, dispatch}]}])

    IO.puts "Started listening on port 8080..."

    SocketeerSupervisor.start_link
  end

  def stop(_state) do
    :ok
  end
end
