# The register module should handle all operations for the
# registers: create a new register structure and, read and write to individual registers.

defmodule Register do
  # TODO Maybe change the register from list to tree form
  # new()
  def new() do
    # here we our register which index 0 represent zero register and index is $1 and so on ...
    # here we have our 32 register and they all from begining have a value
    # reg tuple = {regnumber, regvalue}
    regInListForm = [{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9}, {10, 10}, {11, 11}, {12, 12}, {13, 13}, {14, 14}, {15, 15}, {16, 16}, {17, 17}, {18, 18}, {19, 19}, {20, 20}, {21, 21}, {22, 22}, {23, 23}, {24, 24}, {25, 25}, {26, 26}, {27, 27}, {28, 28}, {29, 29}, {30, 30}, {31, 31}]

    createRegisterInTreeFormat(regInListForm, :nil)
  end

  defp createRegisterInTreeFormat([], tree), do: tree
  defp createRegisterInTreeFormat(regInListForm, tree) do
    # here take a random element from which is used to insert into our tree we do this because inserting random element
    # gives us better probability that our tree will be a balanced tree
    rndElem = Enum.random(regInListForm)

    # we delete that element from the list becuase it will be added to our tree
    newRegInListForm = List.delete(regInListForm, rndElem)

    # deconstruct element
    {key, value} = rndElem

     # insert the element into tree
     newTree = Program.insertElement(key, value, tree)

     # recursively generate the tree for the items that are left in our list
     createRegisterInTreeFormat(newRegInListForm, newTree)

  end

  # read(reg, rs)
  def read(reg, rs), do: Program.lookup(rs, reg)

  # write(reg, rd, s + t) -> reg
  def write(_, 0, _), do: raise "You are trying to write into register 0"
  def write(reg, rd, value), do: Program.modify(rd, value, reg)

end
