defmodule JobServer.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  defp process(tasks_map) do
    tasks = Enum.map(tasks_map, fn task ->
      %Job{
        name: Map.get(task, "name"),
        command: Map.get(task, "command"),
        requires: Map.get(task, "requires", [])
      }
    end)
    graph = DependencyGraph.new(tasks)
    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> {:ok, Poison.encode!(Enum.map(result, &(&1.job)))}
      {:error, message} -> {:error, Poison.encode!(%{response: message})}
    end
  end

  post "/" do
    {status, body} =
      case conn.body_params do
        %{"tasks" => tasks} ->
          case process(tasks) do
            {:ok, response} -> {200, response}
            {:error, error_message} -> {400, error_message}
          end
        _ -> {422, Poison.encode!(%{error: "Expected Payload: { 'tasks': [...] }"})}
      end
      send_resp(conn, status, body)
  end
end
