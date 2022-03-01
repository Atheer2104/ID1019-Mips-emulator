# The module should collect the output from the execution and
# be able to return it as a list of integers.

defmodule Out do

  # creating a new Out we return an empty list
  def new(), do: []

  def put(out, value) do
    # we add the element into our list, accmultor is empty list
    append(out, value, [])
  end

  # if we have empty list then we should add value into acc
  defp append([], value, acc), do: [value | acc]

  # here we take a generalt list and we will call it recursively with tail as new list and
  # we add head into our accmulator
  defp append([head | tail], value, acc), do: append(tail, value, [head | acc])

  # we should return the list we return a tuple with the list in reverse becuase of tailrecursion of how append
  # work the list will be in reverese order so we reverse into right order, check also that we have elements in out
  # ! fix so list is not intrepreted as a char list
  def close(out) when length(out) > 0 do {:Halted, :OutResult, Program.reverse(out)} end
  # handle case where out has no elements inside it
  def close(_), do: {:Halted, :OutResult, "Nothing to output"}

end
