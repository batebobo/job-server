defmodule JobServer.Endpoint do
  use Plug.Router
  require Logger

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  forward("/get_execution_order", to: JobServer.TaskOrderRouter)

  match _ do
    send_resp(conn, 404, "Requested page not found!")
  end

  @spec child_spec(any) :: %{
          id: JobServer.Endpoint,
          start: {JobServer.Endpoint, :start_link, [...]}
        }
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_opts) do
    Logger.info("Starting server at http://localhost:3000/")
    Plug.Cowboy.http __MODULE__, [], port: 3000
  end
end
