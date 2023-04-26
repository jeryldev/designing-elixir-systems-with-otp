defmodule Mastery.Core.QuestionSample do
  alias Mastery.Core.{Template, Quiz, Response}

  generator = %{left: [1, 2], right: [1, 2]}

  checker = fn sub, answer ->
    sub[:left] + sub[:right] == String.to_integer(answer)
  end

  quiz =
    Quiz.new(title: "addition", mastery: 2)
    |> Quiz.add_template(
      name: :single_digit_addition,
      category: :addition,
      instructions: "Add the numbers",
      raw: "<%= @left %> + <%= @right %>",
      generators: generator,
      checker: checker
    )
    |> Quiz.select_question()

  # Incorrect answer
  email = "jill@example.com"
  response = Response.new(quiz, email, "0")
  quiz = Quiz.answer_question(quiz, response)
  quiz.record

  # Correct answer
  quiz = Quiz.select_question(quiz)
  quiz.current_question.asked
  response = Response.new(quiz, email, "4")
  quiz = Quiz.answer_question(quiz, response)
  quiz.record
end
