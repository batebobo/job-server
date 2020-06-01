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
    
    assert DependencyGraph.jobs(graph)
      |> length == 1

    assert DependencyGraph.job_names(graph)
      |> List.first == "Test Job"
  end

  test "Creates a node with two children" do
    job1 = %Job{name: "Job 1", command: "Command 1"}
    job2 = %Job{name: "Job 2", command: "Command 2"}
    job3 = %Job{name: "Job 3", command: "Command 3", dependencies: ["Job 1", "Job 2"]}
    graph = DependencyGraph.new([
      job1, job2, job3
    ])

    assert DependencyGraph.jobs(graph)
      |> length == 3
    
    assert Map.get(graph, "Job 3").dependencies
      |> length == 2

    assert Map.get(graph, "Job 3").in_degree == 0
    assert Map.get(graph, "Job 3").out_degree == 2

    assert Map.get(graph, "Job 1").out_degree == 0
    assert Map.get(graph, "Job 1").in_degree == 1
  end
end
