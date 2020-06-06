defmodule TaskOrderService do
  defp contains(enum, item) do
    Enum.any?(enum, &(&1 == item))
  end

  defp add_edges(graph, tasks) do
    Enum.each(tasks, fn task ->
      Enum.each(task.requires, &(:digraph.add_edge(graph, &1, task.name)))
    end)
    graph
  end

  defp new(tasks) do
    graph = Enum.reduce(tasks, :digraph.new(), fn task, graph ->
      :digraph.add_vertex(graph, task.name)
      graph
    end)

    incorrect_tasks = Enum.reduce(tasks, [], fn task, incorrect_tasks ->
      case Enum.filter(task.requires, &(not contains(:digraph.vertices(graph), &1))) do
        [] -> incorrect_tasks
        incorrect_dependencies -> Enum.concat(incorrect_tasks,
          [%{task: task, missing_requirements: incorrect_dependencies}])
      end
    end)

    case incorrect_tasks do
      [] -> {:ok, add_edges(graph, tasks)}
      _  -> {:incorrect_tasks_error, incorrect_tasks}
    end
  end

  defp find_cycles(graph) do
    cycles = Enum.reduce(:digraph.vertices(graph), [], fn vertex, cycles ->
      case :digraph.get_short_cycle(graph, vertex) do
        false -> cycles
        cycle -> Enum.concat(cycles, [cycle])
      end
    end)
    case cycles do
      [] -> {:ok, []}
      _  -> {:cyclic_tasks_error, cycles}
    end
  end

  def get_tasks_order(tasks) do
    with {:ok, graph} <- new(tasks),
         {:ok, []}    <- find_cycles(graph)
    do
      get_tasks_order(tasks, graph)
    end
  end

  defp get_tasks(tasks, task_names) do
    Enum.map(task_names, &(Enum.find(tasks, fn task -> task.name == &1 end)))
  end

  defp get_tasks_order(tasks, graph) do
    case :digraph_utils.topsort(graph) do
      false -> {:cyclic_tasks_error, []}
      sorted_vertices -> {:ok, get_tasks(tasks, sorted_vertices)}
    end
  end
end
