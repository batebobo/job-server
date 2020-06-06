defmodule TaskOrderResultEncoder do
  @moduledoc """
  Documentation for `TaskOrderResultEncoder`.
  Handles response formatting, depending on the type requested
  """

  @header "#!/usr/bin/env bash \n"

  # Converts a list of tasks to a bash script
  defp get_script_from_tasks(tasks) do
    tasks_commands = Enum.map(tasks, & &1.command)

    Enum.concat([@header], tasks_commands)
    |> Enum.join("\n")
  end

  defp get_error_script(error_message) do
    error_script = "echo '#{error_message}' && echo 'No commands have been executed.'"
    Enum.join([@header, error_script], "\n")
  end

  def encode(result, with: response_type) do
    is_plain_text_requested = response_type == "text/plain"

    case result do
      {:ok, response} when is_plain_text_requested ->
        {:ok, get_script_from_tasks(response)}

      {:ok, response} ->
        {:ok, Poison.encode!(response)}

      {error_type, {message, _}} when is_plain_text_requested ->
        {error_type, get_error_script("Error: #{message}")}

      {error_type, {message, payload}} ->
        {error_type, Poison.encode!(%{error: message, payload: payload})}
    end
  end
end
