defmodule DependencyGraph do
  @moduledoc """
  Documentation for `DependencyGraph`.
  """
  def new(jobs) do
    # Here we dictate how the type will look like
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

  def has_edges?(graph) do
    Enum.any?(Map.values(graph), &(not Enum.empty?(&1.dependencies)))
  end

  def topological_sort(graph) do
    topological_sort_step(graph, root_nodes(graph), [])
  end

  defp topological_sort_step(graph, rootNodes, result) do
    if Enum.empty?(rootNodes) do
      {graph, result}
    else
      currentNode = List.first(rootNodes)
      newRootNodes = Enum.filter(rootNodes, &(&1.job.name != currentNode.job.name))
      newResult = Enum.concat([currentNode], result)
      neighbours = neighbours(graph, currentNode)
      {newGraph,newestRootNodes} = Enum.reduce(neighbours, {graph, newRootNodes}, fn neighbour, {currentGraph,currentRootNodes} ->
        g = remove_edge(currentGraph, currentNode, neighbour)
        if node(g, neighbour.job.name).in_degree == 0 do
          {g, Enum.concat(currentRootNodes, [neighbour])}
        else
          {g, currentRootNodes}
        end
      end)

      topological_sort_step(newGraph, newestRootNodes, newResult)
    end
  end

  defp root_nodes(graph) do
    Enum.filter(Map.values(graph), &(&1.in_degree == 0))
  end

  def neighbours(graph, node) do
    Enum.map(node.dependencies, &(Map.get(graph, &1)))
  end

  def remove_edge(graph, node, child) do
    existingNode = Map.get(graph, node.job.name)
    existingChild = Map.get(graph, child.job.name)
    newDependencies = Enum.filter(existingNode.dependencies, &(&1 != child.job.name))
    newNode = %{existingNode | dependencies: newDependencies}
    newChild = %{existingChild | in_degree: existingChild.in_degree - 1}
    newGraph = Map.put(graph, node.job.name, newNode)
    Map.put(newGraph, child.job.name, newChild)
  end
end
