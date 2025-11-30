defmodule Ankaa.Emergency.Adapter do
  @moduledoc """
  Defines the interface for Emergency Services dispatch.
  """

  @doc """
  Dispatches a mock emergency help request by logging the details.

  ## Parameters
    - payload: A map containing emergency details such as:
      - name: String.t() - Name of the patient
      - address: String.t() - Location of the emergency
      - reason: String.t() - Reason for the emergency
      - vitals: map() - Patient vitals information
      - phone: String.t() - Contact phone number
  """
  @callback dispatch_help(payload :: map()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Cancels a mock emergency dispatch by logging the cancellation.

  ## Parameters
    - dispatch_id: String.t() - The ID of the dispatch to cancel
  """
  @callback cancel_dispatch(dispatch_id :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
