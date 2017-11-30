defmodule WorldTest do
  use ExUnit.Case
  doctest World

  test "greets the world" do
    assert World.hello() == :world
  end
end
