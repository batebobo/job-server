defmodule GraphNode do
  use TypedStruct

  typedstruct do
    field :job, Job, enforce: true
    field :in_degree, number(), enforce: true
    field :dependencies, list(String.t()), default: []
  end

  def name(node) do
    node.job.name
  end
end