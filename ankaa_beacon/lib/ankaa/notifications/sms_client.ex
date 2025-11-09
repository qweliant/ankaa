defmodule Ankaa.Notifications.SMS do
  @moduledoc """
  A mock SMS client that logs messages to the console.
  """
  require Logger

  def send(to_number, body) do
    Logger.info("""

    ==================== MOCK SMS ====================
    [TO]:   #{to_number}
    [BODY]: #{body}
    ==================================================

    """)

    {:ok, "message_sent_to_log"}
  end
end
