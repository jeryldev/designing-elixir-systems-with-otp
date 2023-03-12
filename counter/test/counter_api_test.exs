defmodule CounterApiTest do
  # This is the Test - Boundary Layer tests
  use ExUnit.Case

  # Boundary - API layer test
  test "use counter through API" do
    pid = Counter.start(0)
    assert Counter.state(pid) == 0

    Counter.tick(pid)
    Counter.tick(pid)

    count = Counter.state(pid)
    assert count == 2
  end
end
