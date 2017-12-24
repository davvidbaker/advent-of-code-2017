# --- Day 18: Duet ---
# You discover a tablet containing some strange assembly code labeled simply "Duet". Rather than bother the sound card with it, you decide to run the code yourself. Unfortunately, you don't see any documentation, so you're left to figure out what the instructions mean on your own.

# It seems like the assembly is meant to operate on a set of registers that are each named with a single letter and that can each hold a single integer. You suppose each register should start with a value of 0.

# There aren't that many instructions, so it shouldn't be hard to figure out what they do. Here's what you determine:

# snd X plays a sound with a frequency equal to the value of X.
# set X Y sets register X to the value of Y.
# add X Y increases register X by the value of Y.
# mul X Y sets register X to the result of multiplying the value contained in register X by the value of Y.
# mod X Y sets register X to the remainder of dividing the value contained in register X by the value of Y (that is, it sets X to the result of X modulo Y).
# rcv X recovers the frequency of the last sound played, but only when the value of X is not zero. (If it is zero, the command does nothing.)
# jgz X Y jumps with an offset of the value of Y, but only if the value of X is greater than zero. (An offset of 2 skips the next instruction, an offset of -1 jumps to the previous instruction, and so on.)
# Many of the instructions can take either a register (a single letter) or a number. The value of a register is the integer it contains; the value of a number is that number.

# After each jump instruction, the program continues with the instruction to which the jump jumped. After any other instruction, the program continues with the next instruction. Continuing (or jumping) off either end of the program terminates it.

# For example:

# set a 1
# add a 2
# mul a a
# mod a 5
# snd a
# set a 0
# rcv a
# jgz a -1
# set a 1
# jgz a -2
# The first four instructions set a to 1, add 2 to it, square it, and then set it to itself modulo 5, resulting in a value of 4.
# Then, a sound with frequency 4 (the value of a) is played.
# After that, a is set to 0, causing the subsequent rcv and jgz instructions to both be skipped (rcv because a is 0, and jgz because a is not greater than 0).
# Finally, a is set to 1, causing the next jgz instruction to activate, jumping back two instructions to another jump, which jumps again to the rcv, which ultimately triggers the recover operation.
# At the time the recover operation is executed, the frequency of the last sound played is 4.

# What is the value of the recovered frequency (the value of the most recently played sound) the first time a rcv instruction is executed with a non-zero value?

# [{cmd, register, ?arg}, ...]

# I am treating each register as a little process, mostly for practice using processes that hold state.
defmodule Duet do
  defstruct instructions: [], registry_pid: nil

  def parseInstruction(%{instructions: instructions, registry_pid: _registry_pid}, i)
      when i < 0 or i > length(instructions) do
    IO.puts("\napplication terminated")
  end

  def parseInstruction(duet, i) do
    # :timer.sleep(1000)
    %{instructions: instructions, registry_pid: registry_pid} = duet

    IO.puts("\n/////////////\n/////////////")
    {cmd, register, arg} = Enum.at(instructions, i)
    IO.puts("\n instruction: #{cmd}, #{register}, #{arg}")


    registry = Agent.get(registry_pid, & &1)
    
    case Map.has_key?(registry, register) do
      true ->
        registry
        
        false ->
          {:ok, pid} = Agent.start_link(fn -> {0, nil} end)
          Agent.update(registry_pid, &Map.put(&1, register, pid))
        end
        
        registry = Agent.get(registry_pid, & &1)
        register_pid = Map.fetch!(registry, register)
        
        arg =
        case is_nil(arg) do
          false ->
            case is_integer(arg) do
              true -> arg
              false -> elem(Agent.get(Map.fetch!(registry, arg), fn state -> state end), 0)
            end
            
            true ->
              arg
            end

    IO.puts("\nregister #{register} state")
    IO.inspect(Agent.get(register_pid, fn state -> state end))
            
    IO.puts("\ncmd\s")
    IO.puts(cmd)
    
    IO.puts("\narg")
    IO.inspect(arg)

    status =
      if cmd == "jgz" do
        if elem(Agent.get(register_pid, & &1), 0) > 0 do

          Duet.parseInstruction(duet, i + arg) 
          :done
        else 
          Duet.parseInstruction(duet, i + 1) 
          :done
        end
      else
        case cmd do
          "rcv" ->
            Agent.update(register_pid, fn {val, last_played} ->
              case val do
                0 ->
                  {val, last_played}

                _ ->
                  {last_played, last_played}
              end
            end)

            {val, last_played} = Agent.get(register_pid, & &1)

            if val != 0 && !is_nil(last_played) do
              IO.puts("\nrecovered frequency copied to clipboard: #{last_played}")
              Clipboard.copy!(last_played)
              :done
            else
              :ok
            end

          _ ->
            :ok
        end
      end

    if status == :ok do
      {status, update_function} =
        case cmd do
          "set" -> {:ok, fn {_val, last_played} -> {arg, last_played} end}
          "add" -> {:ok, fn {val, last_played} -> {val + arg, last_played} end}
          "mul" -> {:ok, fn {val, last_played} -> {val * arg, last_played} end}
          "mod" -> {:ok, fn {val, last_played} -> {rem(val, arg), last_played} end}
          "snd" -> {:ok, fn {val, _last_played} -> {val, val} end}
          _ -> {:error, "Don't continue"}
        end

      IO.puts("\nstatus")
      IO.inspect(status)

      with :ok <- status do
        Agent.update(register_pid, update_function)
        IO.puts("\nupdated state")
        IO.inspect(Agent.get(register_pid, fn state -> state end))
      end

      Duet.parseInstruction(duet, i + 1)
    end
  end
end

defmodule Main do
  def main do
    instructions =
      File.read!("day_18/input")
      |> String.split("\n")
      |> Enum.map(&String.split(&1, "\s"))
      |> Enum.map(fn [cmd | args] ->
           args =
             Enum.map(args, fn arg ->
               case Regex.match?(~r/\d/, arg) do
                 true -> String.to_integer(arg)
                 false -> arg
               end
             end)

           register = List.first(args)

           arg =
             case length(args) do
               2 -> List.last(args)
               _ -> nil
             end

           {cmd, register, arg}
         end)

    {:ok, registry_pid} = Agent.start_link(fn -> %{} end)
    duet = %Duet{registry_pid: registry_pid, instructions: instructions}
    Duet.parseInstruction(duet, 0)
  end
end

Main.main()
