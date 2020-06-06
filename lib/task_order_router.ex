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
    TaskOrderService.get_correct_order(for: tasks)
    |> TaskOrderResultEncoder.encode(with: response_type(conn))
  end

  defp response_type(conn) do
    Enum.into(conn.req_headers, Map.new())
        |> Map.get("accept")
  end

  defp wrong_request_body_response(conn) do
    error = {:error, {"Expected Payload: { 'tasks': [...] }", []}}
    {_, message} = TaskOrderResultEncoder.encode(error, with: response_type(conn))
    message
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
          {422, wrong_request_body_response(conn)}
      end

    send_resp(conn, status, body)
  end
end
