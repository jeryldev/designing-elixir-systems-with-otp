defmodule WorkersTest do
  use ExUnit.Case
  doctest Workers

  test "greets the world" do
    assert Workers.hello() == :world
  end
end
