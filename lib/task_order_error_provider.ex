defmodule TaskOrderErrorProvider do
  @moduledoc """
  Documentation for `TaskOrderErrorProvider`.
  Provides error messages and payloads for all errors `TaskOrderService` can return
  """
  @spec format_cycles(list(list(String.t()))) :: String.t()
  defp format_cycles(cycles) do
    Enum.map(cycles, &Enum.join(&1, " -> "))
    |> Enum.join(", ")
  end

  defp missing_task_requirements_error_response(incorrect_tasks) do
    incorrect_tasks_message = Enum.map(incorrect_tasks, fn task ->
      missing_requirements = Enum.join(task.missing_requirements, ", ")
      "Task #{task.task.name} requires tasks [#{missing_requirements}] which do not exist for this job"
    end)
    {incorrect_tasks_message, incorrect_tasks}
  end

  @cycles_error_message "Cycles between tasks have been found"

  @missing_properties_error_message "The following tasks are missing required properties"

  defp cycles_error_response(cycles) do
    message = "#{@cycles_error_message}. #{format_cycles(cycles)}"
    {message, cycles}
  end

  defp missing_properties_error_response(incorrect_tasks) do
    incorrect_tasks_string = Enum.map(incorrect_tasks, &(Map.get(&1, "name")))
    |> Enum.join(", ")
    {"#{@missing_properties_error_message} [#{incorrect_tasks_string}]", incorrect_tasks}
  end
  def get_response(for: error) do
    case error do
      {:missing_properties_error, incorrect_tasks} ->
        {:incorrect_request_format, missing_properties_error_response(incorrect_tasks)}

      {:missing_task_requirements_error, incorrect_tasks} ->
        {:incorrect_request_format, missing_task_requirements_error_response(incorrect_tasks)}

      {:cyclic_tasks_error, cycles} ->
        {:cyclic_tasks_error, cycles_error_response(cycles)}
    end
  end
end
