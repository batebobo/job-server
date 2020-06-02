defmodule DependencyGraphTests do
  import GraphNode
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
    assert Enum.map(neighbours, &(name(&1))) == ["B", "C"]
  end

  test "Removes an edge between two vertices" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B"]}
    job2 = %Job{name: "B", command: "Command 2"}
    graph = DependencyGraph.new([
      job1, job2
    ])

    node1 = Map.get(graph, job1.name)
    node2 = Map.get(graph, job2.name)

    new_graph = DependencyGraph.remove_edge(graph, node1, node2)

    new_node_1 = Map.get(new_graph, job1.name)
    new_node_2 = Map.get(new_graph, job2.name)

    assert Enum.empty?(new_node_1.dependencies)
    assert new_node_2.in_degree == 0
  end

  test "Topological sort for an empty graph" do
    graph = DependencyGraph.new([])

    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> assert result == []
      {:error, message} -> assert(false, "Should have returned an empty ordering for empty graph. Error message: #{message}")
    end
  end

  test "Topological sort for a leaf" do
    job = %Job{name: "A", command: "Command 1"}
    graph = DependencyGraph.new([job])

    perform_assertions = fn(result) ->
      assert length(result) == 1
      assert result
        |> List.first
        |> name == "A"
    end

    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> perform_assertions.(result)
      {:error, message} -> assert(false, "Should have returned the original node. Error message: #{message}")
    end
  end

  test "Topological sort for a simple linear order" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B"]}
    job2 = %Job{name: "B", command: "Command 2", dependencies: ["C"]}
    job3 = %Job{name: "C", command: "Command 3"}

    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> assert Enum.map(result, &(name(&1) == ["C", "B", "A"]))
      {:error, message} -> assert(false, message)
    end

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

    perform_assertions = fn (result) ->
      job_names_order = Enum.map(result, &(name(&1)))

      assert index_of.(job_names_order, "C") < index_of.(job_names_order, "A")
      assert index_of.(job_names_order, "E") < index_of.(job_names_order, "C")
    end

    case DependencyGraph.topological_sort(graph) do
      {:ok, result} -> perform_assertions.(result)
      {:error, message} -> assert(false, message)
    end
  end

  test "Reports an error if there is a cyclic dependency in the tasks" do
    job1 = %Job{name: "A", command: "Command 1", dependencies: ["B"]}
    job2 = %Job{name: "B", command: "Command 2", dependencies: ["C"]}
    job3 = %Job{name: "C", command: "Command 3", dependencies: ["A"]}

    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    case DependencyGraph.topological_sort(graph) do
      {:ok, _} -> assert(false, "Should have thrown an error")
      {:error, _} -> assert true
    end
  end
end
