defmodule JobServer.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  defp get_correct_task_order(tasks_map) do
    tasks = Enum.map(tasks_map, fn task ->
      %Job{
        name: Map.get(task, "name"),
        command: Map.get(task, "command"),
        requires: Map.get(task, "requires", [])
      }
    end)
    graph = DependencyGraph.new(tasks)
    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> {:ok, Enum.map(result, &(&1.job))}
      {:error, message} -> {:error, %{response: message}}
    end
  end

  defp encode(result, response_type) do
    is_plain_text_requested = response_type == "text/plain"
    is_json_requested = response_type == "application/json"
    case result do
      {:error, message} when is_json_requested ->
        {:error, Poison.encode!(%{error: message})}
      {:ok, response} when is_plain_text_requested ->
        {:ok, get_script_from_tasks(response)}
      {:ok, response} ->
        {:ok, Poison.encode!(response)}
    end
  end

  defp get_script_from_tasks(tasks) do
    tasks_commands = Enum.map(tasks, &(&1.command))
    header = "#!/usr/bin/env bash \n"
    Enum.concat([header], tasks_commands)
      |> Enum.join("\n")
  end

  defp process(tasks, conn) do
    response_type = Enum.into(conn.req_headers, Map.new)
      |> Map.get("accept")
    get_correct_task_order(tasks)
      |> encode(response_type)
  end

  post "/" do
    {status, body} =
      case conn.body_params do
        %{"tasks" => tasks} ->
          case process(tasks, conn) do
            {:ok, response} -> {200, response}
            {:error, error_message} -> {400, error_message}
          end
        _ -> {422, Poison.encode!(%{error: "Expected Payload: { 'tasks': [...] }"})}
      end
      send_resp(conn, status, body)
  end
end
