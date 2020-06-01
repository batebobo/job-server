defmodule Job do
  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
    field :command, String.t(), enforce: true
    field :dependencies, list(String.t()), default: []
  end
end