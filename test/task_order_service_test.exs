defmodule TaskOrderServiceTest do
  use ExUnit.Case

  test "Topological sort for an empty graph" do
    case TaskOrderService.get_tasks_order([]) do
      {:ok, result} -> assert result == []
      {:error, message} -> assert(false, "Should have returned an empty ordering for empty graph. Error message: #{message}")
    end
  end

  test "Topological sort for a leaf" do
    job = %JobTask{name: "A", command: "Command 1"}

    case TaskOrderService.get_tasks_order([job]) do
      {:ok, jobs} -> assert List.first(jobs).name == "A"
      {:error, message} -> assert(false, "Should have returned the original node. Error message: #{message}")
    end
  end

  test "Topological sort for a simple linear order" do
    jobs = [%JobTask{name: "A", command: "Command 1", requires: ["B"]},
            %JobTask{name: "B", command: "Command 2", requires: ["C"]},
            %JobTask{name: "C", command: "Command 3"}]

    case TaskOrderService.get_tasks_order(jobs) do
      {:ok, result} -> assert Enum.map(result, &(&1.name)) == ["C", "B", "A"]
      {:error, message} -> assert(false, message)
    end
  end

  test "Finds the proper root nodes while topologically sorting" do
    jobs = [%JobTask{name: "A", command: "Command 1", requires: ["B", "C"]},
            %JobTask{name: "B", command: "Command 2"},
            %JobTask{name: "C", command: "Command 3", requires: ["B", "E"]},
            %JobTask{name: "D", command: "Command 4", requires: ["C"]},
            %JobTask{name: "E", command: "Command 5"}]

    index_of = fn (jobs, job_name) ->
      Enum.find_index(jobs, &(&1 == job_name))
    end

    perform_assertions = fn (result) ->
      job_names_order = Enum.map(result, &(&1.name))

      assert index_of.(job_names_order, "C") < index_of.(job_names_order, "A")
      assert index_of.(job_names_order, "E") < index_of.(job_names_order, "C")
    end

    case TaskOrderService.get_tasks_order(jobs) do
      {:ok, result} -> perform_assertions.(result)
      {:error, message} -> assert(false, message)
    end
  end

  test "Reports an error if there is a cyclic dependency in the tasks" do
    jobs = [%JobTask{name: "A", command: "Command 1", requires: ["B"]},
            %JobTask{name: "B", command: "Command 2", requires: ["C"]},
            %JobTask{name: "C", command: "Command 3", requires: ["A"]}]

    case TaskOrderService.get_tasks_order(jobs) do
      {:cyclic_tasks_error, _} -> assert true
      _ -> assert(false, "Should have thrown a :cyclic_tasks_error")
    end
  end

  test "Reports an error if there is a requirement that does not exist" do
    jobs = [%JobTask{name: "A", command: "Command 1", requires: ["B"]}]

    case TaskOrderService.get_tasks_order(jobs) do
      {:missing_task_requirements_error, _} -> assert true
      _ -> assert(false, "Should have thrown an :incorrect_tasks_error")
    end
  end
end
