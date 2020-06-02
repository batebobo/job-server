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
    existingNode = Map.get(graph, name(node))
    existingChild = Map.get(graph, name(child))

    newDependencies = Enum.filter(existingNode.dependencies, &(&1 != name(child)))
    newNode = %{existingNode | dependencies: newDependencies}
    newChild = %{existingChild | in_degree: existingChild.in_degree - 1}

    newGraph = Map.put(graph, name(node), newNode)
    Map.put(newGraph, name(child), newChild)
  end

  def topological_sort(graph) do
    {graph, result} = topological_sort(graph, root_nodes(graph), [])
    if has_edges?(graph) do
      {:error, "There is a circular dependency between the job's tasks"}
    else
      {:ok, result}
    end
  end

  defp topological_sort(graph, rootNodes, result) do
    if Enum.empty?(rootNodes) do
      {graph, result}
    else
      currentNode = List.first(rootNodes)
      newRootNodes = Enum.filter(rootNodes, &(name(&1) != name(currentNode)))
      newResult = Enum.concat([currentNode], result)
      neighbours = neighbours(graph, currentNode)
      {newGraph,newestRootNodes} = Enum.reduce(neighbours, {graph, newRootNodes}, fn neighbour, {currentGraph,currentRootNodes} ->
        g = remove_edge(currentGraph, currentNode, neighbour)
        if node(g, name(neighbour)).in_degree == 0 do
          {g, Enum.concat(currentRootNodes, [neighbour])}
        else
          {g, currentRootNodes}
        end
      end)

      topological_sort(newGraph, newestRootNodes, newResult)
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
