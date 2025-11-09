defmodule Ankaa.Mailer do
  use Swoosh.Mailer, otp_app: :ankaa
  import Swoosh.Email

  alias Ankaa.Notifications.Invite

  @doc """
  Builds and delivers the care network invitation email.
  """
  def deliver_invite_email(%Invite{} = invite, token) do
    base_url = Application.fetch_env!(:ankaa, :base_url)
    accept_url = "#{base_url}/invites/accept?token=#{token}"

    email =
      new()
      |> to(invite.invitee_email)
      |> from({"Ankaa Health", "noreply@ankaa.health"})
      |> subject("You've been invited to join a care network on Ankaa")
      |> text_body("""
      Hello,

      You have been invited to join a care network on Ankaa.

      To accept this invitation and create your account, please click the link below:
      #{accept_url}

      This link will expire in 7 days.

      If you did not expect this invitation, you can safely ignore this email.

      Thanks,
      The Ankaa Team
      """)
      |> html_body("""
      <html>
        <body>
          <h2>Hello,</h2>
          <p>You have been invited to join a care network on Ankaa.</p>
          <p>To accept this invitation and create your account, please click the link below:</p>
          <p><a href="#{accept_url}">Accept Invitation</a></p>
          <p>This link will expire in 7 days.</p>
          <p>If you did not expect this invitation, you can safely ignore this email.</p>
          <hr>
          <p>Thanks,<br>The Ankaa Team</p>
        </body>
      </html>
      """)

    # Deliver the email using the configured adapter (Inbucket in dev)
    deliver(email)
  end
end
