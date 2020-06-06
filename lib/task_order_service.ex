defmodule TaskOrderService do
  @moduledoc """
  Documentation for `TaskOrderService`.
  A service that is can reorder a collection of tasks
  so that every task is after its requirements
  """

  @spec contains(list(any), any) :: boolean
  defp contains(enum, item) do
    Enum.any?(enum, &(&1 == item))
  end

  @spec add_edges(:digraph.graph(), list(JobTask)) :: :digraph.graph()
  defp add_edges(graph, tasks) do
    Enum.each(tasks, fn task ->
      Enum.each(task.requires, &:digraph.add_edge(graph, &1, task.name))
    end)

    graph
  end

  @spec missing_requirements(:digraph.graph(), list(JobTask)) :: list(any)
  defp missing_requirements(graph, tasks) do
    Enum.reduce(tasks, [], fn task, incorrect_tasks ->
      case Enum.filter(task.requires, &(not contains(:digraph.vertices(graph), &1))) do
        [] ->
          incorrect_tasks

        incorrect_dependencies ->
          Enum.concat(
            incorrect_tasks,
            [%{task: task, missing_requirements: incorrect_dependencies}]
          )
      end
    end)
  end

  @spec new_graph(from: list(JobTask)) ::
          {:ok, :digraph.graph()}
          | {:missing_task_requirements_error, any}
  defp new_graph(from: tasks) do
    graph = :digraph.new()
    Enum.each(tasks, &:digraph.add_vertex(graph, &1.name))

    case missing_requirements(graph, tasks) do
      [] -> {:ok, add_edges(graph, tasks)}
      missing_requirements -> {:missing_task_requirements_error, missing_requirements}
    end
  end

  @spec find_cycles(:digraph.graph()) :: {:ok, list(any)} | {:cyclic_tasks_error, list(any)}
  defp find_cycles(graph) do
    cycles =
      Enum.reduce(:digraph.vertices(graph), [], fn vertex, cycles ->
        case :digraph.get_short_cycle(graph, vertex) do
          false -> cycles
          cycle -> Enum.concat(cycles, [cycle])
        end
      end)

    case cycles do
      [] -> {:ok, []}
      _ -> {:cyclic_tasks_error, cycles}
    end
  end

  @doc """
  Reorders `tasks` so that each task is executed after
  its requirements.

  Returns `{:ok, tasks}` where `tasks` is a list of `JobTask`

  Returns `{:cyclic_tasks_error, cycles}` if there are cycles in the dependency graph

  Returns `{:missing_task_requirements_error, incorrect_tasks}` if some of the task have missing requirements
  """
  @spec get_tasks_order(list(JobTask)) ::
          {:ok, list(JobTask)}
          | {:cyclic_tasks_error, list(any)}
          | {:missing_task_requirements_error, list(any)}
  def get_tasks_order(tasks) do
    with {:ok, graph} <- new_graph(from: tasks),
         {:ok, []} <- find_cycles(graph) do
      get_tasks_order(tasks, graph)
    end
  end

  @spec get_correct_order([{:for, any}, ...]) ::
          {:cyclic_tasks_error, any}
          | {:incorrect_request_format, any}
          | {:ok, [JobTask]}
  def get_correct_order(for: tasks_map) do
    with {:ok, correct_tasks} <- JobTask.from_map(tasks_map),
         {:ok, reordered_tasks} <- get_tasks_order(correct_tasks) do
      {:ok, reordered_tasks}
    else
      error -> TaskOrderErrorProvider.get_response(for: error)
    end
  end

  # Used to retrieve all task information ordered by the `task_names`
  @spec get_tasks(list(JobTask), list(String.t())) :: list(JobTask)
  defp get_tasks(tasks, task_names) do
    Enum.map(task_names, &Enum.find(tasks, fn task -> task.name == &1 end))
  end

  # Performs topological sort on the given `graph` and extracts
  # all tasks data
  @spec get_tasks_order(list(JobTask), :digraph.graph()) ::
          {:ok, list(JobTask)}
          | {:cyclic_tasks_error, list(any)}
  defp get_tasks_order(tasks, graph) do
    case :digraph_utils.topsort(graph) do
      false -> {:cyclic_tasks_error, []}
      sorted_vertices -> {:ok, get_tasks(tasks, sorted_vertices)}
    end
  end
end
