defmodule Mastery.Boundary.Proctor do
  use GenServer
  require Logger
  alias Mastery.Boundary.{QuizManager, QuizSession}

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def init(quizzes) do
    # This is a distributed system, and as with all of them,
    # there are trade-offs. We need to establish a policy.
    # If our server crashes midstream, we’ll lose the timeouts
    # that have already been set. Maybe this is OK;
    # a crash could just notify the proctor and they could intervene manually.
    # But maybe we want to do a little bit of extra work to rehydrate
    # the data in the event of a crash but the init callback
    # gives us a perfectly convenient place to add that code.
    # If you decide that’s where Mastery should go,
    # we’ll leave that code for you to write!

    {:ok, quizzes}
  end

  def schedule_quiz(proctor \\ __MODULE__, quiz, temps, start_at, end_at, notify_pid) do
    quiz = %{
      fields: quiz,
      templates: temps,
      start_at: start_at,
      end_at: end_at,
      notify_pid: notify_pid
    }

    GenServer.call(proctor, {:schedule_quiz, quiz})
  end

  def handle_call({:schedule_quiz, quiz}, _from, quizzes) do
    now = DateTime.utc_now()

    ordered_quizzes =
      [quiz | quizzes]
      |> start_quizzes(now)
      |> Enum.sort(fn a, b -> date_time_less_than_or_equal?(a.start_at, b.start_at) end)

    build_reply_with_timeout({:reply, :ok}, ordered_quizzes, now)
  end

  defp build_reply_with_timeout(reply, quizzes, now) do
    reply
    |> append_state(quizzes)
    |> maybe_append_timeout(quizzes, now)
  end

  defp append_state(tuple, quizzes), do: Tuple.append(tuple, quizzes)

  defp maybe_append_timeout(tuple, [], _now), do: tuple

  defp maybe_append_timeout(tuple, quizzes, now) do
    timeout =
      quizzes
      |> hd()
      |> Map.fetch!(:start_at)
      |> DateTime.diff(now, :millisecond)

    Tuple.append(tuple, timeout)
  end

  defp start_quizzes(quizzes, now) do
    {ready, not_ready} =
      Enum.split_while(quizzes, &date_time_less_than_or_equal?(&1.start_at, now))

    Enum.each(ready, &start_quiz(&1, now))

    not_ready
  end

  def start_quiz(quiz, now) do
    Logger.info("Starting quiz #{quiz.fields.title}...")

    notify_start(quiz)

    QuizManager.build_quiz(quiz.fields)
    Enum.each(quiz.templates, &add_template(quiz, &1))
    timeout = DateTime.diff(quiz.end_at, now, :millisecond)

    if timeout > 0,
      do: Process.send_after(self(), {:end_quiz, quiz.fields.title, quiz.notify_pid}, timeout),
      else: Process.send(self(), {:end_quiz, quiz.fields.title, quiz.notify_pid}, [])
  end

  defp notify_start(%{notify_pid: nil}), do: nil

  defp notify_start(quiz) do
    send(quiz.notify_pid, {:started, quiz.fields.title})
  end

  defp date_time_less_than_or_equal?(a, b) do
    DateTime.compare(a, b) in ~w[lt eq]a
  end

  def add_template(quiz, template_fields) do
    QuizManager.add_template(quiz.fields.title, template_fields)
  end

  def handle_info(:timeout, quizzes) do
    now = DateTime.utc_now()
    remaining_quizzes = start_quizzes(quizzes, now)
    build_reply_with_timeout({:noreply}, remaining_quizzes, now)
  end

  def handle_info({:end_quiz, title, notify_pid}, quizzes) do
    QuizManager.remove_quiz(title)

    title
    |> QuizSession.active_sessions_for()
    |> QuizSession.end_sessions()

    Logger.info("Stopped quiz #{title}.")

    notify_stopped(notify_pid, title)

    handle_info(:timeout, quizzes)
  end

  defp notify_stopped(nil, _title), do: nil

  defp notify_stopped(notify_pid, title) do
    send(notify_pid, {:stopped, title})
  end
end
