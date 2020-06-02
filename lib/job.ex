defmodule Job do
  @moduledoc """
  Documentation for `Job`.
  Struct that represents a job with dependencies
  """
  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
    field :command, String.t(), enforce: true
    field :dependencies, list(String.t()), default: []
  end
end
