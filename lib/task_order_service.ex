defmodule TaskOrderService do
  defp new(tasks) do
    graph = Enum.reduce(tasks, :digraph.new(), fn task, graph ->
      :digraph.add_vertex(graph, task.name)
      graph
    end)

    Enum.each(tasks, fn task ->
      Enum.each(task.requires, &(:digraph.add_edge(graph, &1, task.name)))
    end)
    graph
  end

  def get_tasks_order(tasks) do
    graph = new(tasks)
    cycles = Enum.reduce(:digraph.vertices(graph), [], fn vertex, cycles ->
      case :digraph.get_short_cycle(graph, vertex) do
        false -> cycles
        cycle -> Enum.concat(cycles, [cycle])
      end
    end)

    case cycles do
      [] -> {:ok, get_tasks_order(tasks, graph)}
      _ -> {:error, cycles}
    end
  end

  defp get_tasks(tasks, task_names) do
    Enum.map(task_names, &(Enum.find(tasks, fn task -> task.name == &1 end)))
  end

  defp get_tasks_order(tasks, graph) do
    case :digraph_utils.topsort(graph) do
      false -> {:error, "The task graph is cyclic"}
      sorted_vertices -> get_tasks(tasks, sorted_vertices)
    end
  end
end
