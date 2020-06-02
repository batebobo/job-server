defmodule DependencyGraphTests do
  use ExUnit.Case
  doctest DependencyGraph

  test "Creates an empty dependency graph from nodes" do
    assert DependencyGraph.new([])
     |> Map.keys
     |> Enum.empty?
  end

  test "Creates a non-empty map from a single node" do
    graph = DependencyGraph.new([
      %Job{name: "Test Job", command: "echo 'test'"}
    ])
    
    assert DependencyGraph.nodes(graph)
      |> length == 1
  end

  test "Creates a node with two children" do
    job1 = %Job{name: "Job 1", command: "Command 1"}
    job2 = %Job{name: "Job 2", command: "Command 2"}
    job3 = %Job{name: "Job 3", command: "Command 3", dependencies: ["Job 1", "Job 2"]}
    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    assert DependencyGraph.nodes(graph)
      |> length == 3
    
    assert Map.get(graph, "Job 3").dependencies
      |> length == 2

    assert Map.get(graph, "Job 3").in_degree == 0

    assert Map.get(graph, "Job 1").in_degree == 1
  end

  test "Gets neighbours of a given vertex" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B", "C"]}
    job2 = %Job{name: "B", command: "Command 2"}
    job3 = %Job{name: "C", command: "Command 2"}
    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    neighbours = DependencyGraph.neighbours(graph, Map.get(graph, job1.name))

    assert length(neighbours) == 2
    assert Enum.map(neighbours, &(&1.job.name)) == ["B", "C"]
  end

  test "Removes an edge between two vertices" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B"]}
    job2 = %Job{name: "B", command: "Command 2"}
    graph = DependencyGraph.new([
      job1, job2
    ])

    node1 = Map.get(graph, job1.name)
    node2 = Map.get(graph, job2.name)

    newGraph = DependencyGraph.remove_edge(graph, node1, node2)

    newNode1 = Map.get(newGraph, job1.name)
    newNode2 = Map.get(newGraph, job2.name)
    assert Enum.empty?(newNode1.dependencies)
    assert newNode2.in_degree == 0
  end

  test "Topological sort for a simple linear order" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B"]}
    job2 = %Job{name: "B", command: "Command 2", dependencies: ["C"]}
    job3 = %Job{name: "C", command: "Command 3"}

    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    {_, result} = DependencyGraph.topological_sort(graph)
    assert Enum.map(result, &(&1.job.name)) == ["C", "B", "A"]
  end

  test "Finds the proper root nodes while topologically sorting" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B", "C"]}
    job2 = %Job{name: "B", command: "Command 2"}
    job3 = %Job{name: "C", command: "Command 3", dependencies: ["B", "E"]}
    job4 = %Job{name: "D", command: "Command 4", dependencies: ["C"]}
    job5 = %Job{name: "E", command: "Command 5"}

    graph = DependencyGraph.new([
      job1, job2, job3, job4, job5
    ])

    index_of = fn (jobs, job_name) ->
      Enum.find_index(jobs, &(&1 == job_name))
    end

    {_, result} = DependencyGraph.topological_sort(graph)
    job_names_order = Enum.map(result, &(&1.job.name))

    assert index_of.(job_names_order, "C") < index_of.(job_names_order, "A")
    assert index_of.(job_names_order, "E") < index_of.(job_names_order, "C")
  end
end
