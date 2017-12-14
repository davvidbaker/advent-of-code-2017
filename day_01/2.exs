# You notice a progress bar that jumps to 50% completion. Apparently, the door isn't yet satisfied, but it did emit a star as encouragement. The instructions change:

# Now, instead of considering the next digit, it wants you to consider the digit halfway around the circular list. That is, if your list contains 10 items, only include a digit in your sum if the digit 10/2 = 5 steps forward matches it. Fortunately, your list has an even number of elements.

# For example:

# 1212 produces 6: the list contains 4 items, and all four digits match the digit 2 items ahead.
# 1221 produces 0, because every comparison is between a 1 and a 2.
# 123425 produces 4, because both 2s match each other, but no other digit has a match.
# 123123 produces 12.
# 12131415 produces 4.

ints =
  File.read!("day_01/input")
  |> String.codepoints()
  |> Enum.map(fn x ->
       {int, _rem} = Integer.parse(x)
       int
     end)

len = length(ints)

ints
|> Enum.with_index()
|> Enum.reduce(0, fn {x, ind}, sum ->
     halfway_ind = rem(ind + div(len, 2), len)
     IO.inspect(halfway_ind)

     halfway_int = Enum.at(ints, halfway_ind)

     case x do
       ^halfway_int -> sum + x
       _ -> sum
     end
   end)
|> Clipboard.copy()
|> IO.write()
