# --- Part Two ---
# In the interest of trying to align a little better, the generators get more picky about the numbers they actually give to the judge.

# They still generate values in the same way, but now they only hand a value to the judge when it meets their criteria:

# Generator A looks for values that are multiples of 4.
# Generator B looks for values that are multiples of 8.
# Each generator functions completely independently: they both go through values entirely on their own, only occasionally handing an acceptable value to the judge, and otherwise working through the same sequence of values as before until they find one.

# The judge still waits for each generator to provide it with a value before comparing them (using the same comparison method as before). It keeps track of the order it receives values; the first values from each generator are compared, then the second values from each generator, then the third values, and so on.

# Using the example starting values given above, the generators now produce the following first five values each:

# --Gen. A--  --Gen. B--
# 1352636452  1233683848
# 1992081072   862516352
#  530830436  1159784568
# 1980017072  1616057672
#  740335192   412269392
# These values have the following corresponding binary values:

# 01010000100111111001100000100100
# 01001001100010001000010110001000

# 01110110101111001011111010110000
# 00110011011010001111010010000000

# 00011111101000111101010001100100
# 01000101001000001110100001111000

# 01110110000001001010100110110000
# 01100000010100110001010101001000

# 00101100001000001001111001011000
# 00011000100100101011101101010000
# Unfortunately, even though this change makes more bits similar on average, none of these values' lowest 16 bits match. Now, it's not until the 1056th pair that the judge finds the first match:

# --Gen. A--  --Gen. B--
# 1023762912   896885216

# 00111101000001010110000111100000
# 00110101011101010110000111100000
# This change makes the generators much slower, and the judge is getting impatient; it is now only willing to consider 5 million pairs. (Using the values from the example above, after five million pairs, the judge would eventually find a total of 309 pairs that match in their lowest 16 bits.)

# After 5 million pairs, but using this new generator logic, what is the judge's final count?
use Bitwise

multiplier_a = 16807
multiplier_b = 48271
divisor = 2_147_483_647

input = File.read!("day_15/input")

[initial_a, initial_b] =
  Regex.scan(~r/\d+/, input)
  |> Enum.map(&String.to_integer(List.first(&1)))

defmodule Generator do
  def next(prev, multiplier, divisor) do
    (prev * multiplier) |> rem(divisor)
  end

  def compare(a, b) do
    if (a &&& 65535) == (b &&& 65535) do
      1
    else
      0
    end
  end

  def iterate(n, total_matches, _prev_a, _prev_b, _multiplier_a, _multiplier_b, _divisor)
      when n <= 0 do
    total_matches
  end

  def iterate(n, total_matches, prev_a, prev_b, multiplier_a, multiplier_b, divisor) do
    a = next(prev_a, multiplier_a, divisor)
    b = next(prev_b, multiplier_b, divisor)

    a_valid = rem(a, 4) == 0
    b_valid = rem(b, 8) == 0

    if a_valid && b_valid do
      total_matches = total_matches + compare(a, b)
      iterate(n - 1, total_matches, a, b, multiplier_a, multiplier_b, divisor)
    else
      if a_valid do
        iterate(n, total_matches, prev_a, b, multiplier_a, multiplier_b, divisor)
      else
        if b_valid do
          iterate(n, total_matches, a, prev_b, multiplier_a, multiplier_b, divisor)
        else
          iterate(n, total_matches, a, b, multiplier_a, multiplier_b, divisor)
        end
      end
    end
  end
end

Generator.iterate(5_000_000, 0, initial_a, initial_b, multiplier_a, multiplier_b, divisor)
|> IO.inspect()
|> Clipboard.copy()
