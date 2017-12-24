# --- Day 24: Electromagnetic Moat ---
# The CPU itself is a large, black building surrounded by a bottomless pit. Enormous metal tubes extend outward from the side of the building at regular intervals and descend down into the void. There's no way to cross, but you need to get inside.

# No way, of course, other than building a bridge out of the magnetic components strewn about nearby.

# Each component has two ports, one on each end. The ports come in all different types, and only matching types can be connected. You take an inventory of the components by their port types (your puzzle input). Each port is identified by the number of pins it uses; more pins mean a stronger connection for your bridge. A 3/7 component, for example, has a type-3 port on one side, and a type-7 port on the other.

# Your side of the pit is metallic; a perfect surface to connect a magnetic, zero-pin port. Because of this, the first port you use must be of type 0. It doesn't matter what type of port you end with; your goal is just to make the bridge as strong as possible.

# The strength of a bridge is the sum of the port types in each component. For example, if your bridge is made of components 0/3, 3/7, and 7/4, your bridge has a strength of 0+3 + 3+7 + 7+4 = 24.

# For example, suppose you had the following components:

# 0/2
# 2/2
# 2/3
# 3/4
# 3/5
# 0/1
# 10/1
# 9/10
# With them, you could make the following valid bridges:

# 0/1
# 0/1--10/1
# 0/1--10/1--9/10
# 0/2
# 0/2--2/3
# 0/2--2/3--3/4
# 0/2--2/3--3/5
# 0/2--2/2
# 0/2--2/2--2/3
# 0/2--2/2--2/3--3/4
# 0/2--2/2--2/3--3/5
# (Note how, as shown by 10/1, order of ports within a component doesn't matter. However, you may only use each port on a component once.)

# Of these bridges, the strongest one is 0/1--10/1--9/10; it has a strength of 0+1 + 1+10 + 10+9 = 31.

# What is the strength of the strongest bridge you can make with the components you have available?

# 💁 The bridge is a list where new segments are prepended.
defmodule EM_Moat do
  def parse_input(input) do
    File.read!(input)
    |> String.split("\n")
    |> Enum.map(fn str ->
         [_match, cap1, cap2] = Regex.run(~r/(\d+)\/(\d+)/, str)

         [cap1, cap2]
         |> Enum.map(&String.to_integer(&1))
         |> Enum.sort(&(&1 >= &2))
       end)
  end

  def extend_bridge(current_bridge, remaining_components) when length(remaining_components) == 0 do
    get_strength(current_bridge)
  end

  def extend_bridge(current_bridge, remaining_components) do
    match_value =
      case Enum.empty?(current_bridge) do
        true -> 0
        false -> List.first(current_bridge)
      end

    matching_components =
      remaining_components
      |> Enum.with_index()
      |> Enum.filter(fn {component, _index} ->
           List.last(component) == match_value || List.first(component) == match_value
         end)

    case Enum.empty?(matching_components) do
      true ->
        get_strength(current_bridge)

      false ->
        matching_components
        |> Enum.map(fn {_component, index} ->
             {next_segment, remaining_components} = List.pop_at(remaining_components, index)
             
             next_segment = 
             next_segment
             |> Enum.sort_by(& &1 == match_value)

             extend_bridge(List.flatten(next_segment, current_bridge), remaining_components)
           end)
    end
  end

  def get_strength(bridge) do
    strength =
      bridge
      |> List.flatten()
      |> Enum.sum()

    {bridge, strength}
  end

  def match_port() do
  end
end

components = EM_Moat.parse_input("day_24/input")

bridges =
  EM_Moat.extend_bridge([], components)
  |> List.flatten()
  |> Enum.sort_by(&elem(&1, 1))
  |> Enum.reverse()

bridge_strengths =
  bridges
  |> Enum.map(&elem(&1, 1))
  |> Enum.max()
  |> IO.inspect()
  |> Clipboard.copy()
