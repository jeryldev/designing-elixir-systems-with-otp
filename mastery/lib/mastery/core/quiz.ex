defmodule Mastery.Core.Quiz do
  alias Mastery.Core.{Template, Question, Response}

  defstruct title: nil,
            mastery: 3,
            templates: %{},
            used: [],
            current_question: nil,
            last_response: nil,
            record: %{},
            mastered: []

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_template(quiz, fields) do
    template = Template.new(fields)

    templates =
      update_in(
        quiz.templates,
        [template.category],
        &add_to_list_or_nil(&1, template)
      )

    %{quiz | templates: templates}
  end

  def add_to_list_or_nil(nil, template), do: [template]

  def add_to_list_or_nil(templates, template), do: [template | templates]
end
