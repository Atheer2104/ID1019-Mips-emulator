
# The module should be able to create a code segment and a
# data segment given a program description. It should provide functions
# to read from the code segment and both read and write to a data
# segment.

defmodule Program do

  # load(prgm) -> {code, data}
  # here code will be a list where we have instructions
  # data will be our memory
  def load(prgm) do
    {:prgm, code, data} = prgm
    startAddr = 0x0
    mem = createMemory(data, startAddr)
    {code, mem}
  end

  def read_instruction(code, pc) do
    index = div(pc, 4)
    # we will retrive code from the calculated index by pc using Enum.at
    Enum.at(code, index)
  end

  # {memory for address and values, memory for data diretiive}
  # memory for data diretiive = {:label, valueaddress, leftTree, RightTree}
  # empty tree = :nil
  # {:node, Label, Address, value ,LeftTree, RightTree} (Directive Data Mem)
  # {:node, Adress, value ,LeftTree, RightTree} (Dynamic Data Mem)

  defp createMemory(dataList, addr) do
    # here we are creating the directive data memory ie the data we know when we compile code that is specified in data diretive
    # it will return to us the mem in list form and current addr it is at
    {dataDirectiveMem, currDirectiveMemAddr} = createDirectiveDataMemory(dataList, addr)

    # here we are creating the dynamic data Mem which in begining will hold the directive data so it will create from it
    # note we reverse dataDirectiveMem because of tailrecursion it is reversed
    {dynamicMem, currDynamicMemAddr} = createDynamicDataMemory(dataList, reverse(dataDirectiveMem), addr)

    # here we are creating the data directive Mem in in tree form, :nil represent starting tree which is empty
    dataDirectiveMemTree = createMemoryInTreeFormat(dataDirectiveMem, :nil)

    # here we are creating the dynamic data Mem in tree form
    dynamicMemTree = createMemoryInTreeFormat(dynamicMem, :nil)

    # here we are returning our mem which will be dynamic Mem tree along with addr and data directive Mem with addr
    {{dynamicMemTree, currDynamicMemAddr}, {dataDirectiveMemTree, currDirectiveMemAddr}}
  end

  # ! NOTE: I DO NOT SUPPORT BYTE ADDRESSING, so imm don't matter
  # here rs is label for data directive
  def loadFromMemory(mem, _, rs) when is_atom(rs) do
    # deconstruct Mem
    {{dynamicMemTree, _}, {dataDirectiveMemTree, _}} = mem

    # check for addr for label in data Directive Mem Tree
    addrLabel = lookup(rs, dataDirectiveMemTree)
    if addrLabel === :no do
      # give error becuase the data directive could not be found
      {:ERROR, "Can't load from a data derictive which does not exist"}
    else
      # we have the addr and will know find the value of the data directive in dynamic Mem Tree
      lookup(addrLabel, dynamicMemTree)
    end
  end

  # here rs is an address
  def loadFromMemory(mem, _, rs) do
    # deconstruct Mem
    {{dynamicMemTree, _}, {_, _}} = mem

    # here we are loading from address so directly perform lookup iun Dynamic data mem tree
    value = lookup(rs, dynamicMemTree)
    if value === :no do
      # give error data was not found
      {:ERROR, "Can't load from that memory addres because it does not exist"}
    else
      # retrun value
      value
    end
  end

  # can store via label or directly via adress
  # can store into an existing place in memory
  # can store a new value in memory
  def writeToMemory(mem, rt, _, rs) when is_atom(rs) do
    # deconstruct Mem
    {{dynamicMemTree, currDynamicMemAddr}, {dataDirectiveMemTree, currDirectiveMemAddr}} = mem

    # check for addr for label in data Directive Mem Tree
    addrLabel = lookup(rs, dataDirectiveMemTree)

    if addrLabel === :no do
      # ! here will assume that we can't store in a place where the data derictive doesn't exist
      {:ERROR, "Trying to store in Mem using a data derictive which doesn't exist"}
    else
      # the label we are trying to store at does exist
      IO.puts("Written in existance place in memory")

      # we modify the value of the address connected to the data directive
      newDynamicMemTree = modify(addrLabel, rt, dynamicMemTree)

      # return our new Mem
      {{newDynamicMemTree, currDynamicMemAddr}, {dataDirectiveMemTree, currDirectiveMemAddr}}
    end
  end

  def writeToMemory(mem, rt, _, rs) do
    # deconstruct Mem
    {{dynamicMemTree, currDynamicMemAddr}, {dataDirectiveMemTree, currDirectiveMemAddr}} = mem

    # here we are loading from address so directly perform lookup iun Dynamic data mem tree
    found = lookup(rs, dynamicMemTree)

    if found === :no do
      # because the addr doesn't exist in dynamic Mem tree we know this will be a new memory place
      IO.puts("Written into new place in memory")

      # we insert it inro our dynamic Mem Tree
      newDynamicMemTree = insertElement(rs, rt, dynamicMemTree)

      # return our new Mem
      {{newDynamicMemTree, currDynamicMemAddr},{dataDirectiveMemTree, currDirectiveMemAddr}}
    else
      # here we know we are writing into an existing place in memory
      IO.puts("Written in existance place in memory")

      # we modify the value at that address
      newDynamicMemTree = modify(rs, rt, dynamicMemTree)

      # return our new Mem
      {{newDynamicMemTree, currDynamicMemAddr},{dataDirectiveMemTree, currDirectiveMemAddr}}
    end
  end

  # when a label defined in code needs to be written to Mem
  def writeToDirectiveDataMemory(mem, directiveName, pc) do
    # deconstruct Mem
    {{dynamicMemTree, _} ,{dataDirectiveMemTree, currDirectiveMemAddr}} = mem

    # we check that addr is avaible because user can use sw and choose an address that we might think is availble
    # ! this is extra precuation because we can write into a place using sw where our currAddr for directive currently
    # ! points at so next time we write to dynamic Mem there will not be valid because addr value in directive mem in
    # ! dynamic points to not a data directive value
    addr = checkAddrAvaible(currDirectiveMemAddr, dynamicMemTree)

    # we insert the data to data directive Mem
    newDataDirectiveMemTree = insertElement(directiveName, addr, dataDirectiveMemTree)

    # we insert also the data directive value into dynamic Mem
    newDynamicMemTree = insertElement(addr, pc, dynamicMemTree)

    # returning our new mem here they have both same curr addr
    {{newDynamicMemTree, addr}, {newDataDirectiveMemTree, addr}}
  end

  defp checkAddrAvaible(addr, tree) do
    # we check if addr is avaible in our mem tree
    action = lookup(addr, tree)


    if action === :no do
      # address is avaible so just return it
      addr
    else
      # here addr is not avaible so will check if next addr is avaible recursively
      checkAddrAvaible(addr+0x4, tree)
    end
  end

  # this instrucitons is used to retrive what index in our list the instruction is located at
  def gePcForSpecificInstruction(code, instruction) do
    # here we set start index to 0 so we check from begining
    gePcForSpecificInstruction(code, instruction, 0)
  end

  # ! need to take into account the instruction does not exist
  #defp gePcForSpecificInstruction(code, insruciton, index) when index > length(code) do raise  end
  defp gePcForSpecificInstruction(code, insruciton, index) do

    if index > length(code) do
      raise "A label in code was not found"
    end

    # we retrive current instruction
    currInstruciton = Enum.at(code, index)

    # check if retrived instruction is the same as the instruction we are looking for
    if currInstruciton === insruciton do
      # same instructuion return the current index
      index
      else
        # check next index recursively
        gePcForSpecificInstruction(code, insruciton, index+1)
    end
  end

  # here we take our code data and turn into data directive Mem
  defp createDirectiveDataMemory(dataList, addr) do
    # we set acc to empty list in begining
    createDirectiveDataMemory(dataList, addr, [])
  end

  # when we react empty list we know we are done no more data directive so return acc with acc
  defp createDirectiveDataMemory([], addr, acc), do: {acc, addr}


  defp createDirectiveDataMemory(dataList, addr, acc) do
    # here we are deconstructing data list here we get the label and corresponding value
    [{:label, label}, {:word, _} | tail] = dataList

    # we recusrively call createDirectiveDataMemory but with tail this time we increase addr
    # we also in create new accmulator where the static data will be represented by tuple {:label, addr}
    createDirectiveDataMemory(tail, addr + 0x4, [{label, addr} | acc])
  end

  # here we create our dynamic mem we need both datalist and the datadirective Mem
  defp createDynamicDataMemory(dataList, dataDirectiveMem, addr) do
    # set acc to empty list
    createDynamicDataMemory(dataList, dataDirectiveMem, addr, [])
  end

  # here if both dataList and data directive Mem is empty we know we are done
  defp createDynamicDataMemory([], [], addr, acc), do: {acc, addr}

  # here we need orginal dataList so we can get value for that data directive
  # we also need our dataDirectiveMem so we know the address of the label
  defp createDynamicDataMemory(dataList, dataDirectiveMem, addr, acc) do
    # we do pattern matchning in dataDirectiveMem we only need the addr of label
    [{_, labelAddr} | taildataDirectiveMem] = dataDirectiveMem

    # here we need value
    [{:label, _}, {:word, value} | tailDataList] = dataList

    # here the dynamic array same concept as we create the data directive Mem we represnt by tuple {addr, value}
    createDynamicDataMemory(tailDataList, taildataDirectiveMem, addr + 0x4, [{labelAddr, value} | acc])
  end

  # here we know that the list of Mem is empty so we return the tree which is an accmulator
  defp createMemoryInTreeFormat([], tree), do: tree

  defp createMemoryInTreeFormat(memInListForm, tree) do
    # here take a random element from which is used to insert into our tree we do this because inserting random element
    # gives us better probability that our tree will be a balanced tree
    rndElem = Enum.random(memInListForm)

    # we delete that element from the list becuase it will be added to our tree
    newMemInListForm = List.delete(memInListForm, rndElem)

    # deconstruct elment for data directive it will be {:label, addr} for dynamic it will be {addr, label}, :label and key will be our key into tree
    # our tree it will have nodes that have key, value pairs and not just a value
    {key, value} = rndElem

    # insert the element into tree
    newTree = insertElement(key, value, tree)

    # recursively generate the tree for the items that are left in our list
    createMemoryInTreeFormat(newMemInListForm, newTree)
  end


  # here if our current tree is :nil we know here is where we should insert element so we return the node
  # with our values inside of it
  def insertElement(key, value, :nil), do: {:node, key, value, :nil, :nil}

  # here we do binary search because our tree will be a bst tree and insert the element into correct place
  def insertElement(key, value, {:node, k, v, left, right}) do
    # check key of our element with current node key value
    if key < k do
      # here we know the element should be inserted into left side of the tree notice here we are calling the function on the left
      # part of the tree becuase that where this is added and we will do this recursively and when we reach empty tree we will in
      # base case retun our new node so then it will be placed in correct place
      {:node, k, v, insertElement(key, value, left), right}
    else
      # here the element should be added into right part of the tree becase key was larger than current node key
      {:node, k, v, left, insertElement(key, value, right)}
    end

  end

  # if we do lookup ie search for an empty tree we return :no
  def lookup(_, :nil), do: :no

  # if we are at a specific node where the key matches with the key we look for we return the value of that node
  def lookup(key, {:node, key, value, _, _}), do: value

  # general case we perform again bst and look for whre to perform the lookup
  def lookup(key, {:node, k, _, left, right}) do
    if key < k do
      lookup(key, left)
    else
      lookup(key, right)
    end
  end


  # if we modify an empty tree we return :nil
  def modify(_, _, :nil), do: :nil

  # if we found the node which should be modified then we return that node with new value inside but everything else is the same
  def modify(key, value, {:node, key, _, left, right}), do: {:node, key, value, left, right}

  # here we do again binary search and we call modify on that part of the tree where the element should be
  def modify(key, value, {:node, k, v, left, right}) do
    if key < k do
      {:node, k, v, modify(key, value, left), right}
    else
      {:node, k, v, left, modify(key, value, right)}
    end
  end


  # this functions will reverse a list
  def reverse(list), do: reverse(list, [])

  defp reverse([], acc), do: acc
  defp reverse([head | tail], acc), do: reverse(tail, [head | acc])





end
