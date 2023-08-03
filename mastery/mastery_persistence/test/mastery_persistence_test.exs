defmodule MasteryPersistenceTest do
  use ExUnit.Case
  alias MasteryPersistence.{Response, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    response = %{
      quiz_title: :simple_addition,
      template_name: :single_digit_addition,
      to: "3 + 4",
      email: "student@example.com",
      answer: "7",
      correct: true,
      timestamp: DateTime.utc_now()
    }

    {:ok, %{response: response}}
  end

  test "responses are recorded", %{response: response} do
    initial_responses_count = Repo.aggregate(Response, :count, :id)
    assert :ok = MasteryPersistence.record_response(response)
    assert Repo.aggregate(Response, :count, :id) == initial_responses_count + 1
    all_responses_emails = Repo.all(Response) |> Enum.map(fn r -> r.email end)
    assert response.email in all_responses_emails
  end

  test "a function can be run in the saving transaction", %{response: response} do
    assert response.answer == MasteryPersistence.record_response(response, & &1.answer)
  end

  test "an error in the function rolls back the save", %{response: response} do
    initial_responses_count = Repo.aggregate(Response, :count, :id)

    assert_raise RuntimeError, fn ->
      MasteryPersistence.record_response(response, fn _ -> raise "oops" end)
    end

    assert Repo.aggregate(Response, :count, :id) == initial_responses_count
  end

  test "simple reporting", %{response: response} do
    MasteryPersistence.record_response(response)
    MasteryPersistence.record_response(response)

    response
    |> Map.put(:email, "other_#{response.email}")
    |> MasteryPersistence.record_response()

    report = MasteryPersistence.report(response.quiz_title)
    assert Map.get(report, response.email) == 2
    assert Map.get(report, "other_#{response.email}") == 1
  end
end
