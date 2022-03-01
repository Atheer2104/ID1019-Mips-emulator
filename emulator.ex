defmodule Emulator do

  # our code will be a list where inside it we have tuples that each stand for mips instruction that we are supposed to implement
  # ex code()
  #[{:addi, 1, 0, 5},
  # {:lw, 2, 0, :arg},
  # {:add, 4, 2, 1},
  # :halt]

  # this is represtionion for data segment data()
  # data = [ {:label, :arg}, {:word, 12} ]

  # a program in our will be following tuple
  # {:prgm, code(), data()}

  #code = [{:add, 4, 2, 1}, :halt]
  #data = []
  #prgm = {:prgm, code, data}
  #prgm = {:prgm, [{:add, 4, 2, 1}, :halt], []}

  # [{:lw, 2, 0, :arg}, {:label, loop}, {:sw, 1, 0, 0x24}, {:beq, 1, 1, :loop}, :halt]
  # {:prgm, [{:lw, 2, 0, :arg}, {:beq, 1, 1, :loop}, {:sw, 1, 0, 0x24}, {:label, :loop}, {:add, 4, 2, 1} ,:halt], [ {:label, :arg}, {:word, 12}, {:label, :varx}, {:word, 25}]}

  def testrun() do
    {code, data} = Program.load({:prgm, [{:lw, 2, 0, :arg}, {:beq, 1, 1, :loop}, {:sw, 1, 0, 0x24}, {:label, :loop}, {:addi, 1, 1, 0x4}, {:out, 1}, {:out, 2} ,:halt], [ {:label, :arg}, {:word, 12}, {:label, :varx}, {:word, 25}]})
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end

  def testrun1() do
    {code, data} = Program.load({:prgm, [{:add, 4, 2, 1}, :halt], [ {:label, :arg}, {:word, 12}, {:label, :varx}, {:word, 25}]})
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end

  def testrun2() do
    {code, data} = Program.load({:prgm, [{:add, 4, 2, 1}, {:addi, 1, 1, 0x41}, {:out, 4}, {:out, 1},:halt], []})
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end


  def testrun3() do
    {code, data} = Program.load({:prgm, [{:lw, 2, 0, :arg}, {:label, :loop}, {:sw, 1, 0, 0x24}, {:beq, 1, 1, :gg} ,:halt], [ {:label, :arg}, {:word, 12}]})
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end

  def testrun4() do
    {code, data} = Program.load({:prgm, [{:sw, 2, 0, 0x24}, {:sub, 9, 5, 8}, {:lw, 9, 0, 0x24}, {:out, 9}, :halt], [ {:label, :arg}, {:word, 12}, {:label, :varx}, {:word, 25}]})
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end

  def run(prgm) do
    {code, data} = Program.load(prgm)
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, data, out)
  end

  def run(pc, code, reg, mem, out) do
    next = Program.read_instruction(code, pc)
    case next do
      # Out.close(out)
      :halt -> Out.close(out)

      # reg(rd) := reg(rs) + reg(rt)
      {:add, rd, rs, rt} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        t = Register.read(reg, rt)
        IO.puts(s + t)
        reg = Register.write(reg, rd, s + t) # well, almost
        IO.puts("add instruction")
        # go to next instruction
        run(pc, code, reg, mem, out)

      # reg(rd) := reg(rs) - reg(rt)
      {:sub, rd, rs, rt} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        t = Register.read(reg, rt)
        reg = Register.write(reg, rd, s - t)
        IO.puts("sub instruction")
        # go to next instruction
        run(pc, code, reg, mem, out)

       # reg(rt) := reg(rs) + signext(imm)
       {:addi, rd, rs, imm} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        reg = Register.write(reg, rd, s + imm)
        IO.puts("addi instruction")
        # go to next instruction
        run(pc, code, reg, mem, out)

      # reg(rt) := mem[reg(rs) + signext(imm)]
      {:lw, rt, imm, rs} ->
        pc = pc + 4
        value = Program.loadFromMemory(mem, imm, rs)
        # value will be the value from memory or an error in tuple form
        case value do
          {:ERROR, _} ->
            # sending back error which is value also on what line the problem notice decrment pc because we earlier incremented it
            {value, "There was an error in lw instruction at this line: #{div(pc-4,4)}"}
            #mem
          _ ->
            reg = Register.write(reg, rt, value)
            Register.read(reg, rt)
            # go to next instruction
            run(pc, code, reg, mem, out)
        end

        # mem[reg(rs) + signext(imm)] := reg(rt)
        {:sw, rt, imm, rs} ->
          pc = pc + 4
          regValue = Register.read(reg, rt)
          mem = Program.writeToMemory(mem, regValue, imm, rs)

          # mem can be the new state of the memory or an error in tuple form
          case mem do
            {:ERROR, _} ->
              {mem, "There was an error in sw instruction at this line: #{div(pc-4,4)}"}
            _ ->
              #newMem
              # go to next instruction
              run(pc, code, reg, mem, out)
          end

        {:label, name} ->
          pc = pc + 4
          # here will write the label into derictive memory and in dynamic memory it will include the program counter for the label
          mem = Program.writeToDirectiveDataMemory(mem, name, pc-4)
          IO.puts("label instruction")
          # go to next instruction
          run(pc, code, reg, mem, out)

        # if reg(rs) == reg(rt) then PC = BTA else NOP
        {:beq, rs, rt, label}  ->
          pc = pc + 4
          s = Register.read(reg, rs)
          t = Register.read(reg, rt)
          # check if reg values are the same
          if s === t do
            #IO.puts("Jump")
            # here we know we should jump
            value = Program.loadFromMemory(mem, 0, label)
            # value will be pc counter or and error
            case value do
              {:ERROR, _} ->
                # here because we knew we should but we got error this means that we are jumping and the label we tried to load
                # from memory doesn't yet because it further down in code
                # here will go through the code and try to find that label
                # ! this doesn't take account into what if we specify a code that does not exist
                index = Program.gePcForSpecificInstruction(code, {:label, label})
                # here we will calculate the new pc
                newPc = index*0x4
                # jump to that specific pc
                # ! note here are not jumping to the correct pc that we are supposed by mips
                # ! we are jumping to the start of label
                run(newPc, code, reg, mem, out)
              _ ->
                # no error so the label we have earlier met in code so we know what pc it has
                # ! note here we are correctly jumping to the correct pc if we look at mips we are adding + 0x4
                run(value+0x4, code, reg, mem, out)
              end
          else
            # here the value in register didn't match so we are not going to jump
            # go to next instruction
            run(pc, code, reg, mem, out)
          end

       #here out it will collect everything that is supposed to be written in a list and when program terminates it will output the list
       {:out, rs} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        out = Out.put(out, s)
        # go to next instruction
        run(pc, code, reg, mem, out)
    end
  end
end
