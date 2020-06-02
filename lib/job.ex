defmodule Job do
  @moduledoc """
  Documentation for `Job`.
  Struct that represents a job with dependencies
  """
  use TypedStruct

  @derive{Poison.Encoder, except: [:requires]}
  typedstruct do
    field :name, String.t()
    field :command, String.t()
    field :requires, list(String.t()), default: []
  end
end
