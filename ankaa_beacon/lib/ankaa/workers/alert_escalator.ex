defmodule Ankaa.Workers.AlertEscalator do
  @moduledoc """
  Background job to handle alert escalations.
  """
  use GenServer

  # GenServer implementation to periodically check for alerts that need
  # escalation and trigger the escalation process
  def init(init_arg) do
    {:ok, init_arg}
  end
end
