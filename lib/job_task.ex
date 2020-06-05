defmodule JobTask do
  @moduledoc """
  Documentation for `Task`.
  Struct that represents a task with dependencies
  """
  use TypedStruct

  @derive{Poison.Encoder, except: [:requires]}
  typedstruct do
    field :name, String.t(), enforce: true
    field :command, String.t(), enforce: true
    field :requires, list(String.t()), default: []
  end
end
