defmodule JobTask do
  @moduledoc """
  Documentation for `Task`.
  Struct that represents a task with dependencies
  """
  use TypedStruct

  @derive{Poison.Encoder, except: [:requires]}
  typedstruct do
    field :name, String.t(), enforce: true
    field :command, String.t(), enforce: true
    field :requires, list(String.t()), default: []
  end

  @spec from_map(any) ::
    {:missing_properties_error, any} |
    {:ok, list(JobTask)}
  def from_map(tasks_map) do
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
    case incorrect_tasks do
      [] -> {:ok, correct_tasks}
      _  -> {:missing_properties_error, incorrect_tasks}
    end
  end
end
