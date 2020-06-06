defmodule JobServer.TaskOrderRouter do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  defp format_cycles(cycles) do
    Enum.map(cycles, &(Enum.join(&1, "->")))
      |> Enum.join(", ")
  end

  defp cycles_error_message do
    "Cycles between tasks have been found"
  end

  defp cycles_error_response(cycles) do
    {cycles_error_message(), format_cycles(cycles)}
  end

  defp incorrect_input_error_message do
    "The following tasks have incorrect format"
  end

  defp incorrect_tasks_error_response(incorrect_tasks) do
    message = "#{incorrect_input_error_message()}. The listed task requirements do not exist:"
    {message, Poison.encode!(incorrect_tasks)}
  end

  defp get_correct_order(for: tasks_map) do
    {correct_tasks, incorrect_tasks} = Enum.reduce(tasks_map, {[], []}, fn task, {correct, incorrect} ->
      if Map.has_key?(task, "name") && Map.has_key?(task, "command") do
        new_task = %JobTask{
            name: Map.get(task, "name"),
            command: Map.get(task, "command"),
            requires: Map.get(task, "requires", [])
          }
        {Enum.concat(correct, [new_task]), incorrect}
      else
        {correct, Enum.concat(incorrect, [task])}
      end
    end)

    if not Enum.empty? incorrect_tasks do
      {:error, :incorrect_tasks_error, {incorrect_input_error_message(), Poison.encode!(incorrect_tasks)}}
    else
      case TaskOrderService.get_tasks_order(correct_tasks) do
        {:cyclic_tasks_error, cycles} -> {:error, :cyclic_tasks_error, cycles_error_response(cycles)}
        {:incorrect_tasks_error, incorrect_tasks} ->
          {:error, :incorrect_tasks_error, incorrect_tasks_error_response(incorrect_tasks)}
        result -> result
      end
    end
  end

  defp encode(result, with: response_type) do
    is_plain_text_requested = response_type == "text/plain"
    is_json_requested = response_type == "application/json"
    case result do
      {:error, error_type, {message, payload}} when is_json_requested ->
        {error_type, Poison.encode!(%{error: message, payload: payload})}
      {:error, error_type, {message, payload}} ->
        {error_type, "Error: #{message}. Payload: #{payload}"}
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
    get_correct_order(for: tasks)
      |> encode(with: response_type)
  end

  post "/" do
    {status, body} =
      case conn.body_params do
        %{"tasks" => tasks} ->
          case process(tasks, conn) do
            {:ok, response} -> {200, response}
            {:incorrect_tasks_error, error_message} -> {422, error_message}
            {:cyclic_tasks_error, error_message} -> {400, error_message}
          end
        _ -> {422, Poison.encode!(%{error: "Expected Payload: { 'tasks': [...] }"})}
      end
      send_resp(conn, status, body)
  end
end
