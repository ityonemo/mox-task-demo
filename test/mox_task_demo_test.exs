defmodule Api do
  @callback func :: String.t
end

Mox.defmock(Mocked, for: Api)

defmodule MoxTaskDemoTest do
  use ExUnit.Case, async: true  # <== yes this works in concurrently run tests.

  setup do
    Mox.expect(Mocked, :func, fn -> "foo" end)
    :ok
  end

  test "mox can work correctly with tasks" do
    test_pid = self()

    Task.start(fn ->
      result = Mocked.func()
      send(test_pid, {:result, result})
    end)

    assert_receive {:result, "foo"}
  end

  test "also with async tasks" do
    future = Task.async(fn -> Mocked.func() end)
    assert "foo" = Task.await(future)
  end

  test "but not with spawn" do
    test_pid = self()

    # this should crash
    spawn(fn ->
      result = Mocked.func()
      send(test_pid, {:result, result})
    end)

    assert_receive {:result, "foo"}
  end

  test "how it works" do
    test_pid = self()
    IO.inspect(self(), label: "this is the test pid")
    Task.start(fn ->
      callers = Process.get(:"$callers")
      IO.inspect(callers, label: "the task knows its caller")

      ancestors = Process.get(:"$ancestors")
      IO.inspect(ancestors, label: "the task knows its ancestors")

      send(test_pid, :unblock)
    end)

    assert_receive :unblock

    {:ok, sup} = Task.Supervisor.start_link()
    IO.inspect(sup, label: "this is the supervisor")

    Task.Supervisor.start_child(sup, fn ->
      callers = Process.get(:"$callers")
      IO.inspect(callers, label: "when supervised, the caller is who called the task")

      ancestors = Process.get(:"$ancestors")
      IO.inspect(ancestors, label: "the ancestors list is the chain of process ownership")

      send(test_pid, :unblock)
    end)
    assert_receive :unblock

    spawn(fn ->
      IO.inspect(self(), label: "this process owns the new supervisor")
      {:ok, sup2} = Task.Supervisor.start_link()
      IO.inspect(sup2, label: "this is the new supervisor")
      send(test_pid, sup2)
      # keep this spawned thread from dying
      receive do :never -> :die end
    end)

    assert_receive sup2

    Task.Supervisor.start_child(sup2, fn ->
      callers = Process.get(:"$callers")
      IO.inspect(callers, label: "caller is still the test_pid")
      ancestors = Process.get(:"$ancestors")
      IO.inspect(ancestors, label: "NB: ancestors might not have the caller")

      send(test_pid, :unblock)
    end)
    assert_receive :unblock
  end

end
