defmodule Ankaa.Emergency.MockDispatcher do
  @moduledoc """
  A mock emergency dispatcher that logs dispatch actions instead of performing real operations.
  Useful for development and testing environments.
  """
  @behaviour Ankaa.Emergency.Adapter
  require Logger

  @impl true
  def dispatch_help(payload) do
    if payload.address == "error" do
      {:error, "Simulated Dispatch Failure"}
    else
      Process.sleep(500)
      dispatch_id = "mock_dispatch_#{System.unique_integer([:positive])}"

      Logger.critical("""
      \n
      🚨 ========================================================== 🚨
      🚨 [MOCK EMS DISPATCH REQUEST SENT]
      🚨 ID: #{dispatch_id}
      🚨 ----------------------------------------------------------
      🚨 PATIENT:   #{payload.name}
      🚨 LOCATION:  #{payload.address}
      🚨 REASON:    #{payload.reason}
      🚨 VITALS:    #{inspect(payload.vitals)}
      🚨 CONTACT:   #{payload.phone}
      🚨 ========================================================== 🚨
      \n
      """)

      {:ok, dispatch_id}
    end
  end

  @impl true
  def cancel_dispatch(dispatch_id) do
    Logger.info("✅ [MOCK EMS] Dispatch #{dispatch_id} successfully CANCELLED.")
    {:ok, "cancelled"}
  end
end
