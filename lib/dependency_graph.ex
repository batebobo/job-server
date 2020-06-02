defmodule DependencyGraph do
  import GraphNode
  @moduledoc """
  Documentation for `DependencyGraph`.
  """
  def new(jobs) do
    Enum.reduce(jobs, Map.new, fn x, map ->
      if Map.has_key?(map, x.name) do
        # Log a warning that the key exists
        map
      end
      in_degree = Enum.count(jobs, fn job ->
        Enum.any?(job.dependencies, &(&1 == x.name)) end)
      Map.put_new(
        map,
        x.name,
        %GraphNode{
          job: x,
          in_degree: in_degree,
          dependencies: x.dependencies
        })
    end)
  end

  def nodes(graph) do
    Map.values(graph)
  end

  def node(graph, name) do Map.get(graph, name) end

  def remove_edge(graph, node, child) do
    existing_node = Map.get(graph, name(node))
    existing_child = Map.get(graph, name(child))

    new_dependencies = Enum.filter(existing_node.dependencies, &(&1 != name(child)))
    new_node = %{existing_node | dependencies: new_dependencies}
    new_child = %{existing_child | in_degree: existing_child.in_degree - 1}

    new_graph = Map.put(graph, name(node), new_node)
    Map.put(new_graph, name(child), new_child)
  end

  def topological_sort(graph) do
    {graph, result} = topological_sort(graph, root_nodes(graph), [])
    if has_edges?(graph) do
      {:error, "There is a circular dependency between the job's tasks"}
    else
      {:ok, result}
    end
  end

  defp topological_sort(graph, root_nodes, result) do
    if Enum.empty?(root_nodes) do
      {graph, result}
    else
      current_node = List.first(root_nodes)
      new_root_nodes = Enum.filter(root_nodes, &(name(&1) != name(current_node)))
      new_result = Enum.concat([current_node], result)
      neighbours = neighbours(graph, current_node)
      {new_graph, newest_root_nodes} = Enum.reduce(neighbours, {graph, new_root_nodes}, fn neighbour, {current_graph, current_root_nodes} ->
        g = remove_edge(currentGraph, current_node, neighbour)
        if node(g, name(neighbour)).in_degree == 0 do
          {g, Enum.concat(current_root_nodes, [neighbour])}
        else
          {g, current_root_nodes}
        end
      end)

      topological_sort(new_graph, newest_root_nodes, new_result)
    end
  end

  defp has_edges?(graph) do
    Enum.any?(Map.values(graph), &(not Enum.empty?(&1.dependencies)))
  end

  defp root_nodes(graph) do
    Enum.filter(Map.values(graph), &(&1.in_degree == 0))
  end

  def neighbours(graph, node) do
    Enum.map(node.dependencies, &(Map.get(graph, &1)))
  end
end
