defmodule MoxTaskDemoTest do
  use ExUnit.Case
  doctest MoxTaskDemo

  test "greets the world" do
    assert MoxTaskDemo.hello() == :world
  end
end
