defmodule JobServer.TaskOrderRouter do
  @moduledoc """
  Documentation for `TaskOrderRouter`.
  Handles requests for task reordering.
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # Gets the value of the "Accept" header,
  # Finds the correct order of tasks and
  # encodes the result in the requested format
  defp get_correct_order(tasks, conn) do
    response_type =
      Enum.into(conn.req_headers, Map.new())
      |> Map.get("accept")

    TaskOrderService.get_correct_order(for: tasks)
    |> TaskOrderResultEncoder.encode(with: response_type)
  end

  post "/" do
    {status, body} =
      case conn.body_params do
        %{"tasks" => tasks} ->
          case get_correct_order(tasks, conn) do
            {:ok, response} -> {200, response}
            {:incorrect_request_format, error_message} -> {422, error_message}
            {:cyclic_tasks_error, error_message} -> {400, error_message}
          end

        _ ->
          {422, Poison.encode!(%{error: "Expected Payload: { 'tasks': [...] }"})}
      end

    send_resp(conn, status, body)
  end
end
