⚠️ incomplete

# --- Part Two ---
# As you congratulate yourself for a job well done, you notice that the documentation has been on the back of the tablet this entire time. While you actually got most of the instructions correct, there are a few key differences. This assembly code isn't about sound at all - it's meant to be run twice at the same time.

# Each running copy of the program has its own set of registers and follows the code independently - in fact, the programs don't even necessarily run at the same speed. To coordinate, they use the send (snd) and receive (rcv) instructions:

# snd X sends the value of X to the other program. These values wait in a queue until that program is ready to receive them. Each program has its own message queue, so a program can never receive a message it sent.
# rcv X receives the next value and stores it in register X. If no values are in the queue, the program waits for a value to be sent to it. Programs do not continue to the next instruction until they have received a value. Values are received in the order they are sent.
# Each program also has its own program ID (one 0 and the other 1); the register p should begin with this value.

# For example:

# snd 1
# snd 2
# snd p
# rcv a
# rcv b
# rcv c
# rcv d
# Both programs begin by sending three values to the other. Program 0 sends 1, 2, 0; program 1 sends 1, 2, 1. Then, each program receives a value (both 1) and stores it in a, receives another value (both 2) and stores it in b, and then each receives the program ID of the other program (program 0 receives 1; program 1 receives 0) and stores it in c. Each program now sees a different value in its own copy of register c.

# Finally, both programs try to rcv a fourth time, but no data is waiting for either of them, and they reach a deadlock. When this happens, both programs terminate.

# It should be noted that it would be equally valid for the programs to run at different speeds; for example, program 0 might have sent all three values and then stopped at the first rcv before program 1 executed even its first instruction.

# Once both of your programs have terminated (regardless of what caused them to do so), how many times did program 1 send a value?

# I am treating each register as a little process, mostly for practice using processes that hold state.
defmodule Duet do
  defstruct instructions: [], registry_pid: nil, program_id: nil, queue: []

  def parse_input(raw_input) do
    File.read!(raw_input)
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
  end
  

  def parse_instruction(%{instructions: instructions, registry_pid: _registry_pid, program_id: _program_id}, i)
      when i < 0 or i > length(instructions) do
    IO.puts("\napplication terminated")
  end

  def parse_instruction(duet, i) do
    # :timer.sleep(1000)
    %{instructions: instructions, registry_pid: registry_pid , program_id: program_id} = duet

    IO.puts("\n/////////////\n/////////////")
    {cmd, register, arg} = Enum.at(instructions, i)
    IO.puts("\n instruction: #{cmd}, #{register}, #{arg}")


    registry = Agent.get(registry_pid, & &1)
    
    case Map.has_key?(registry, register) do
      true ->
        registry
        
        false ->
          initial_val = case (register == "p") do
            true -> program_id
            false -> 0
          end
          {:ok, pid} = Agent.start_link(fn -> {initial_val, nil} end)
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

          Duet.parse_instruction(duet, i + arg) 
          :done
        else 
          Duet.parse_instruction(duet, i + 1) 
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

      Duet.parse_instruction(duet, i + 1)
    end
  end
end

defmodule Main do
  def main do
    instructions = Duet.parse_input("day_18/input")

    for i <- 0..1 do
      {:ok, registry_pid} = Agent.start_link(fn -> %{} end)
      duet = %Duet{registry_pid: registry_pid, instructions: instructions, program_id: i}
      Duet.parse_instruction(duet, 0)
      :timer.sleep(2000)
    end
  end
end

Main.main()
