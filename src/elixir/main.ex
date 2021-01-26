defmodule Main do
  def main do
    Enum.reduce(0 .. 999999, :gb_sets.new, &:gb_sets.add(&1, &2))
    |> :gb_sets.size
    |> IO.puts
  end
end
