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
      out_degree = x.dependencies
        |> length
      in_degree = Enum.count(jobs, fn job -> 
        Enum.any?(job.dependencies, &(&1 == x.name)) end)
      Map.put_new(
        map,
        x.name,
        %GraphNode{
          job: x,
          in_degree: in_degree,
          out_degree: out_degree,
          dependencies: x.dependencies
        })
    end)
  end

  def job_names(graph) do
    Map.keys(graph)
  end

  def jobs(graph) do
    Map.values(graph)
  end

  def job(graph, name) do Map.get(graph, name) end

  def find_cycle(graph) do
    graph
  end

  def sort(graph) do
    graph
  end
end
