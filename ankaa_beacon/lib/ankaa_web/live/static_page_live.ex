defmodule AnkaaWeb.StaticPageLive do
  @moduledoc """
  A LiveView for rendering static legal pages such as Privacy Policy,
  Disclaimer, and Cookie Policy.
  """
  use AnkaaWeb, :live_view


  @impl true
  def mount(_params, session, socket) do
    socket = mount_current_user(socket, session)
    {:ok, assign(socket, :page_title, "Legal")}
  end

  defp mount_current_user(socket, session) do
    user_token = session["user_token"]
    user = user_token && Ankaa.Accounts.get_user_by_session_token(user_token)

    assign(socket, :current_user, user) # Assigns user struct OR nil
  end

  # This render clause handles the :privacy action
  @impl true
  def render(%{live_action: :privacy} = assigns) do
    ~H"""
      <div class="max-w-3xl mx-auto py-8">
        <%= raw(privacy_policy_html()) %>
      </div>
    """
  end

  # This render clause handles the :disclaimer action
  @impl true
  def render(%{live_action: :disclaimer} = assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 prose">
     <%= raw(disclaimer_policy_html()) %>
    </div>
    """
  end

  # This render clause handles the :cookies action
  @impl true
  def render(%{live_action: :cookies} = assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 prose">
     <%= raw(cookie_policy_html()) %>
    </div>
    """
  end

  defp privacy_policy_html do
    """
      <style>
        [data-custom-class='body'], [data-custom-class='body'] * {
        background: transparent !important;
        }
        [data-custom-class='title'], [data-custom-class='title'] * {
        font-family: Arial !important;
        font-size: 26px !important;
        color: #000000 !important;
        }
        [data-custom-class='subtitle'], [data-custom-class='subtitle'] * {
        font-family: Arial !important;
        color: #595959 !important;
        font-size: 14px !important;
        }
        [data-custom-class='heading_1'], [data-custom-class='heading_1'] * {
        font-family: Arial !important;
        font-size: 19px !important;
        color: #000000 !important;
        }
        [data-custom-class='heading_2'], [data-custom-class='heading_2'] * {
        font-family: Arial !important;
        font-size: 17px !important;
        color: #000000 !important;
        }
        [data-custom-class='body_text'], [data-custom-class='body_text'] * {
        color: #595959 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        }
        [data-custom-class='link'], [data-custom-class='link'] * {
        color: #3030F1 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        word-break: break-word !important;
        }
      </style>
      <div data-custom-class="body">
      <div>
        <strong>
            <span style="font-size: 26px;">
              <span data-custom-class="title">
                  <bdt class="block-component"></bdt>
                  <bdt class="question">
                    <h1>PRIVACY NOTICE</h1>
                  </bdt>
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </strong>
      </div>
      <div>
        <span style="color: rgb(127, 127, 127);">
            <strong>
              <span style="font-size: 15px;">
                  <span data-custom-class="subtitle">
                    Last updated
                    <bdt class="question">November 06, 2025</bdt>
                  </span>
              </span>
            </strong>
        </span>
      </div>
      <div><br></div>
      <div><br></div>
      <div><br></div>
      <div style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span data-custom-class="body_text">
                  This Privacy Notice for
                  <bdt class="question noTranslate">Qwelian Tanner</bdt>
                  <bdt class="block-component"></bdt>
                  </bdt> (
                  <bdt class="block-component"></bdt>
                  "<strong>we</strong>," "<strong>us</strong>," or "<strong>our</strong>"
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
              <span data-custom-class="body_text">
                  ), describes how and why we might access, collect, store, use, and/or share (
                  <bdt class="block-component"></bdt>
                  "<strong>process</strong>"
                  <bdt class="statement-end-if-in-editor"></bdt>
                  ) your personal information when you use our services (
                  <bdt class="block-component"></bdt>
                  "<strong>Services</strong>"
                  <bdt class="statement-end-if-in-editor"></bdt>
                  ), including when you:
              </span>
            </span>
        </span>
        <span style="font-size: 15px;">
            <span style="color: rgb(127, 127, 127);">
              <span data-custom-class="body_text">
                  <span style="color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        <bdt class="block-component"></bdt>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    Visit our website
                    <bdt class="block-component"></bdt>
                    at
                    <span style="color: rgb(0, 58, 250);">
                        <bdt class="question noTranslate"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com">https://www.safehemo.com</a></bdt>
                    </span>
                    <span style="font-size: 15px;">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px;">
                                <span style="color: rgb(89, 89, 89);">
                                    <bdt class="statement-end-if-in-editor"> or any website of ours that links to this Privacy Notice</bdt>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div>
      <bdt class="block-component">
        <span style="font-size: 15px;">
            <span style="font-size: 15px;">
              <span style="color: rgb(127, 127, 127);">
                  <span data-custom-class="body_text">
                    <span style="color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <bdt class="block-component"></bdt>
      </bdt>
      </span></span></span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              Use
              <bdt class="question">Safe Hemo</bdt>
              .
              <bdt class="question">Safe Hemo is a proof-of-concept for a real-time monitoring and alert system designed specifically for home hemodialysis. The system focuses on detecting critical risks such as severe hypotension and blood loss, integrating with health monitoring setups to provide automated emergency detection, and caresupport alerts. This ensures patient safety even without immediate medical assistance.
                  The project was born from a personal need to make home hemodialysis safer and more accessible. As someone who has experienced the challenges of home dialysis firsthand, I understand the importance of having a reliable safety net that can detect and respond to critical situations, especially when medical assistance isn't immediately available.
              </bdt>
            </span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span style="color: rgb(127, 127, 127);">
              <span data-custom-class="body_text">
                  <span style="color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        <bdt class="block-component"></bdt>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    Engage with us in other related ways, including any sales, marketing, or events
                    <span style="font-size: 15px;">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px;">
                                <span style="color: rgb(89, 89, 89);">
                                    <bdt class="statement-end-if-in-editor"></bdt>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span style="color: rgb(127, 127, 127);">
              <span data-custom-class="body_text">
                  <strong>Questions or concerns? </strong>Reading this Privacy Notice will help you understand your privacy rights and choices. We are responsible for making decisions about how your personal information is processed. If you do not agree with our policies and practices, please do not use our Services.
                  <bdt class="block-component"></bdt>
                  If you still have any questions or concerns, please contact us at
                  <bdt class="question noTranslate"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a></bdt>
                  .
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <strong>
            <span style="font-size: 15px;">
              <span data-custom-class="heading_1">
                  <h2>SUMMARY OF KEY POINTS</h2>
              </span>
            </span>
        </strong>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong><em>This summary provides key points from our Privacy Notice, but you can find out more details about any of these topics by clicking the link following each key point or by using our </em></strong></span></span><a data-custom-class="link" href="#toc"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text"><strong><em>table of contents</em></strong></span></span></a><span style="font-size: 15px;"><span data-custom-class="body_text"><strong><em> below to find the section you are looking for.</em></strong></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>What personal information do we process?</strong> When you visit, use, or navigate our Services, we may process personal information depending on how you interact with us and the Services, the choices you make, and the products and features you use. Learn more about </span></span><a data-custom-class="link" href="#personalinfo"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">personal information you disclose to us</span></span></a><span data-custom-class="body_text">.</span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong>Do we process any sensitive personal information? </strong>Some of the information may be considered
              <bdt class="block-component"></bdt>
              "special" or "sensitive"
              <bdt class="statement-end-if-in-editor"></bdt>
              in certain jurisdictions, for example your racial or ethnic origins, sexual orientation, and religious beliefs.
              <bdt class="block-component"></bdt>
              We may process sensitive personal information when necessary with your consent or as otherwise permitted by applicable law. Learn more about
            </span>
        </span>
        <a data-custom-class="link" href="#sensitiveinfo"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">sensitive information we process</span></span></a><span data-custom-class="body_text">.</span>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong>Do we collect any information from third parties?</strong>
              <bdt class="block-component"></bdt>
              We may collect information from public databases, marketing partners, social media platforms, and other outside sources. Learn more about
            </span>
        </span>
        <a data-custom-class="link" href="#othersources"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">information collected from other sources</span></span></a><span data-custom-class="body_text">.</span>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>How do we process your information?</strong> We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law. We may also process your information for other purposes with your consent. We process your information only when we have a valid legal reason to do so. Learn more about </span></span><a data-custom-class="link" href="#infouse"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">how we process your information</span></span></a><span data-custom-class="body_text">.</span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong>
                  In what situations and with which
                  <bdt class="block-component"></bdt>
                  parties do we share personal information?
              </strong>
              We may share information in specific situations and with specific
              <bdt class="block-component"></bdt>
              third parties. Learn more about
            </span>
        </span>
        <a data-custom-class="link" href="#whoshare"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">when and with whom we share your personal information</span></span></a>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              .
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong>How do we keep your information safe?</strong> We have adequate
              <bdt class="block-component"></bdt>
              organizational
              <bdt class="statement-end-if-in-editor"></bdt>
              and technical processes and procedures in place to protect your personal information. However, no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure, so we cannot promise or guarantee that hackers, cybercriminals, or other
              <bdt class="block-component"></bdt>
              unauthorized
              <bdt class="statement-end-if-in-editor"></bdt>
              third parties will not be able to defeat our security and improperly collect, access, steal, or modify your information. Learn more about
            </span>
        </span>
        <a data-custom-class="link" href="#infosafe"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">how we keep your information safe</span></span></a><span data-custom-class="body_text">.</span>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>What are your rights?</strong> Depending on where you are located geographically, the applicable privacy law may mean you have certain rights regarding your personal information. Learn more about </span></span><a data-custom-class="link" href="#privacyrights"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">your privacy rights</span></span></a><span data-custom-class="body_text">.</span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong>How do you exercise your rights?</strong> The easiest way to exercise your rights is by
              <bdt class="block-component"></bdt>
              visiting
              <span style="color: rgb(0, 58, 250);">
                  <bdt class="question"><a target="_blank" data-custom-class="link" href="https://wyrfihqus37.typeform.com/to/jMjKXzfd">https://wyrfihqus37.typeform.com/to/jMjKXzfd</a></bdt>
              </span>
              <bdt class="else-block"></bdt>
              , or by contacting us. We will consider and act upon any request in accordance with applicable data protection laws.
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">Want to learn more about what we do with any information we collect? </span></span><a data-custom-class="link" href="#toc"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">Review the Privacy Notice in full</span></span></a><span style="font-size: 15px;"><span data-custom-class="body_text">.</span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><br></div>
      <div id="toc" style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(0, 0, 0);">
                  <strong>
                    <span data-custom-class="heading_1">
                        <h2>TABLE OF CONTENTS</h2>
                    </span>
                  </strong>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#infocollect"><span style="color: rgb(0, 58, 250);">1. WHAT INFORMATION DO WE COLLECT?</span></a></span></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <a data-custom-class="link" href="#infouse">
              <span style="color: rgb(0, 58, 250);">
                  2. HOW DO WE PROCESS YOUR INFORMATION?
                  <bdt class="block-component"></bdt>
              </span>
            </a>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <a data-custom-class="link" href="#legalbases">
              <span style="color: rgb(0, 58, 250);">
                  3. <span style="font-size: 15px;"><span style="color: rgb(0, 58, 250);">WHAT LEGAL BASES DO WE RELY ON TO PROCESS YOUR PERSONAL INFORMATION?</span></span>
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </a>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="#whoshare">4. WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?</a></span>
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
              </a>
              <span style="color: rgb(127, 127, 127);">
                  <span style="color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        <span style="color: rgb(89, 89, 89);">
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#cookies"><span style="color: rgb(0, 58, 250);">5. DO WE USE COOKIES AND OTHER TRACKING TECHNOLOGIES?</span></a><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span><bdt class="block-component"></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89);"><bdt class="block-component"></bdt></span></span><bdt class="block-component"></bdt></span></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#inforetain"><span style="color: rgb(0, 58, 250);">6. HOW LONG DO WE KEEP YOUR INFORMATION?</span></a><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89);"><bdt class="block-component"></bdt></span></span></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#infosafe"><span style="color: rgb(0, 58, 250);">7. HOW DO WE KEEP YOUR INFORMATION SAFE?</span></a><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt></span></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="#privacyrights">8. WHAT ARE YOUR PRIVACY RIGHTS?</a></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#DNT"><span style="color: rgb(0, 58, 250);">9. CONTROLS FOR DO-NOT-TRACK FEATURES<bdt class="block-component"></bdt></span></a></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#uslaws"><span style="color: rgb(0, 58, 250);">10. DO UNITED STATES RESIDENTS HAVE SPECIFIC PRIVACY RIGHTS?</span></a></span><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt></div><div style="line-height: 1.5;"><a data-custom-class="link" href="#otherlaws"><span style="color: rgb(0, 58, 250); font-size: 15px;">11. DO OTHER REGIONS HAVE SPECIFIC PRIVACY RIGHTS?</span></a><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></span></div><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><a data-custom-class="link" href="#policyupdates"><span style="color: rgb(0, 58, 250);">12. DO WE MAKE UPDATES TO THIS NOTICE?</span></a></span></div><div style="line-height: 1.5;"><a data-custom-class="link" href="#contact"><span style="color: rgb(0, 58, 250); font-size: 15px;">13. HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</span></a></div><div style="line-height: 1.5;"><a data-custom-class="link" href="#request"><span style="color: rgb(0, 58, 250);">14. HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?</span></a></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><br></div><div id="infocollect" style="line-height: 1.5;"><span style="color: rgb(0, 0, 0);"><span style="color: rgb(0, 0, 0); font-size: 15px;"><span style="font-size: 15px; color: rgb(0, 0, 0);"><span style="font-size: 15px; color: rgb(0, 0, 0);"><span id="control" style="color: rgb(0, 0, 0);"><strong><span data-custom-class="heading_1"><h2>1. WHAT INFORMATION DO WE COLLECT?</h2></span></strong></span></span></span></span></span><span data-custom-class="heading_2" id="personalinfo" style="color: rgb(0, 0, 0);"><span style="font-size: 15px;"><strong><h3>Personal information you disclose to us</h3></strong></span></span><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong><em>In Short:</em></strong></span></span></span></span><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong><em> </em></strong><em>We collect personal information that you provide to us.</em></span></span></span></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We collect personal information that you voluntarily provide to us when you <span style="font-size: 15px;"><bdt class="block-component"></bdt></span>register on the Services, </span><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"></bdt></span></span><span data-custom-class="body_text">express an interest in obtaining information about us or our products and Services, when you participate in activities on the Services, or otherwise when you contact us.</span></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong>Personal Information Provided by You.</strong> The personal information that we collect depends on the context of your interactions with us and the Services, the choices you make, and the products and features you use. The personal information we collect may include the following:<span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">names</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">phone numbers</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">email addresses</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">mailing addresses</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">job titles</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">usernames</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">passwords</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">contact preferences</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">contact or authentication data</bdt></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></div><div id="sensitiveinfo" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>Sensitive Information.</strong> <bdt class="block-component"></bdt>When necessary, with your consent or as otherwise permitted by applicable law, we process the following categories of sensitive information:<bdt class="forloop-component"></bdt></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">health data</bdt></span></span></li></ul><div><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">biometric data</bdt></span></span></li></ul><div><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="forloop-component"></bdt></span><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"><bdt class="block-component"></bdt></bdt></span></span></span></span><bdt class="block-component"></span></span></bdt></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">All personal information that you provide to us must be true, complete, and accurate, and you must notify us of any changes to such personal information.</span></span></span></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
        <span data-custom-class="heading_2" style="color: rgb(0, 0, 0);">
            <span style="font-size: 15px;">
              <strong>
                  <h3>Information automatically collected</h3>
              </strong>
            </span>
        </span>
        <span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong><em>In Short:</em></strong></span></span></span></span><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong><em> </em></strong><em>Some information — such as your Internet Protocol (IP) address and/or browser and device characteristics — is collected automatically when you visit our Services.</em></span></span></span></span></span></span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We automatically collect certain information when you visit, use, or navigate the Services. This information does not reveal your specific identity (like your name or contact information) but may include device and usage information, such as your IP address, browser and device characteristics, operating system, language preferences, referring URLs, device name, country, location, information about how and when you use our Services, and other technical information. This information is primarily needed to maintain the security and operation of our Services, and for our internal analytics and reporting purposes.</span></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  Like many businesses, we also collect information through cookies and similar technologies.
                  <bdt class="block-component"></bdt>
                  You can find out more about this in our Cookie Notice:
                  <bdt class="statement-end-if-in-editor"></bdt>
                  <bdt class="block-component"></bdt>
                  <span style="color: rgb(0, 58, 250);">
                    <bdt class="question"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com/cookie-policy">https://www.safehemo.com/cookie-policy</a></bdt>
                  </span>
                  .
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt>
              </span>
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  The information we collect includes:
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <em>Log and Usage Data.</em> Log and usage data is service-related, diagnostic, usage, and performance information our servers automatically collect when you access or use our Services and which we record in log files. Depending on how you interact with us, this log data may include your IP address, device information, browser type, and settings and information about your activity in the Services<span style="font-size: 15px;"> </span>(such as the date/time stamps associated with your usage, pages and files viewed, searches, and other actions you take such as which features you use), device event information (such as system activity, error reports (sometimes called
                    <bdt class="block-component"></bdt>
                    "crash dumps"
                    <bdt class="statement-end-if-in-editor"></bdt>
                    ), and hardware settings).
                    <span style="font-size: 15px;">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px;">
                                <span style="color: rgb(89, 89, 89);">
                                    <bdt class="statement-end-if-in-editor"></bdt>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt>
      </span></span></span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <em>Location Data.</em> We collect location data such as information about your device's location, which can be either precise or imprecise. How much information we collect depends on the type and settings of the device you use to access the Services. For example, we may use GPS and other technologies to collect geolocation data that tells us your current location (based on your IP address). You can opt out of allowing us to collect this information either by refusing access to the information or by disabling your Location setting on your device. However, if you choose to opt out, you may not be able to use certain aspects of the Services.
                    <span style="font-size: 15px;">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px;">
                                <span style="color: rgb(89, 89, 89);">
                                    <bdt class="statement-end-if-in-editor"></bdt>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div>
        <bdt class="block-component">
            <span style="font-size: 15px;">
        </bdt>
        </bdt><bdt class="statement-end-if-in-editor"></bdt></bdt></span></span></span>
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <span data-custom-class="body_text">
                        <span style="color: rgb(89, 89, 89); font-size: 15px;">
                          <span data-custom-class="body_text">
                              <bdt class="statement-end-if-in-editor">
                                <bdt class="block-component"></bdt>
                              </bdt>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span data-custom-class="heading_2" id="othersources" style="color: rgb(0, 0, 0);">
            <span style="font-size: 15px;">
              <strong>
                  <h3>Information collected from other sources</h3>
              </strong>
            </span>
        </span>
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span data-custom-class="body_text">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <strong><em>In Short: </em></strong>
                          <em>
                              We may collect limited data from public databases, marketing partners,
                              <span style="color: rgb(89, 89, 89);">
                                <span style="font-size: 15px;">
                                    <em>
                                      <span data-custom-class="body_text">
                                          <bdt class="block-component"></bdt>
                                      </span>
                                    </em>
                                </span>
                              </span>
                              and other outside sources.
                          </em>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  In order to enhance our ability to provide relevant marketing, offers, and services to you and update our records, we may obtain information about you from other sources, such as public databases, joint marketing partners, affiliate programs, data providers,
                  <span style="color: rgb(89, 89, 89);">
                    <span style="font-size: 15px;">
                        <span data-custom-class="body_text">
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
                  and from other third parties. This information includes mailing addresses, job titles, email addresses, phone numbers, intent data (or user
                  <bdt class="block-component"></bdt>
                  behavior
                  <bdt class="statement-end-if-in-editor"></bdt>
                  data), Internet Protocol (IP) addresses, social media profiles, social media URLs, and custom profiles, for purposes of targeted advertising and event promotion.
                  <span style="color: rgb(89, 89, 89);">
                    <span style="font-size: 15px;">
                        <span data-custom-class="body_text">
                          <span style="color: rgb(89, 89, 89);">
                              <span style="font-size: 15px;">
                                <span data-custom-class="body_text">
                                    <bdt class="block-component"></bdt>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        </span>
        <span data-custom-class="body_text">
            <span style="color: rgb(89, 89, 89);">
              <span style="font-size: 15px;">
                  <span data-custom-class="body_text">
                    <span style="color: rgb(89, 89, 89);">
                        <span style="color: rgb(89, 89, 89);">
                          <bdt class="block-component">
                              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                                <span data-custom-class="body_text">
                                    <span style="color: rgb(89, 89, 89); font-size: 15px;">
                                      <span data-custom-class="body_text">
                                          <bdt class="statement-end-if-in-editor">
                                            <bdt class="statement-end-if-in-editor"></bdt>
                                          </bdt>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </bdt>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        </span></span>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="infouse" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>2. HOW DO WE PROCESS YOUR INFORMATION?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
              <span data-custom-class="body_text">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <strong><em>In Short: </em></strong>
                          <em>
                              We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law.
                              <bdt class="block-component"></bdt>
                              We process the personal information for the following purposes listed below.
                              <bdt class="statement-end-if-in-editor"></bdt>
                              We may also process your information for other purposes
                              <bdt class="block-component"></bdt>
                              only with your prior explicit
                              <bdt class="else-block"></bdt>
                              consent.
                          </em>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong>We process your personal information for a variety of reasons, depending on how you interact with our Services, including:</strong>
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <strong>To facilitate account creation and authentication and otherwise manage user accounts. </strong>We may process your information so you can create and log in to your account, as well as keep your account in working order.
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px;">
                                <span style="color: rgb(89, 89, 89);">
                                    <span data-custom-class="body_text">
                                      <span style="font-size: 15px;">
                                          <span style="color: rgb(89, 89, 89);">
                                            <span data-custom-class="body_text">
                                                <bdt class="statement-end-if-in-editor"></bdt>
                                            </span>
                                          </span>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <span style="font-size: 15px; color: rgb(89, 89, 89);">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </span>
      </span></span></span></span></span></span></span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <strong>To deliver and facilitate delivery of services to the user. </strong>We may process your information to provide you with the requested service.
                    <span style="font-size: 15px;">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                    <span data-custom-class="body_text">
                                      <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                          <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                            <span data-custom-class="body_text">
                                                <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                                      <span data-custom-class="body_text">
                                                        <span style="font-size: 15px;">
                                                            <span style="color: rgb(89, 89, 89);">
                                                              <span data-custom-class="body_text">
                                                                  <span style="font-size: 15px;">
                                                                    <span style="color: rgb(89, 89, 89);">
                                                                        <span data-custom-class="body_text">
                                                                          <bdt class="statement-end-if-in-editor"></bdt>
                                                                        </span>
                                                                    </span>
                                                                  </span>
                                                              </span>
                                                            </span>
                                                        </span>
                                                      </span>
                                                  </span>
                                                </span>
                                            </span>
                                          </span>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <span style="font-size: 15px; color: rgb(89, 89, 89);">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </span>
      </span></span></span></span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
      <span style="font-size: 15px; color: rgb(89, 89, 89);">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </span>
      </li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"></bdt>
      </span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <strong>To send administrative information to you. </strong>We may process your information to send you details about our products and services, changes to our terms and policies, and other similar information.
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                <span style="font-size: 15px; color: rgb(89, 89, 89);">
                                    <span data-custom-class="body_text">
                                      <bdt class="statement-end-if-in-editor"></bdt>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"></bdt>
      </span></span></span></span></span></span></span></span></span></span></span></span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </li></ul>
      <p style="font-size: 15px; line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"></bdt>
        </span></span></span></span></span></span></span></span></span></span></span></li>
      </ul>
      <p style="font-size: 15px; line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </p>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span style="color: rgb(89, 89, 89);">
                  <span style="color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        <strong>To enable user-to-user communications. </strong>We may process your information if you choose to use any of our offerings that allow for communication with another user.
                        <span style="color: rgb(89, 89, 89);">
                          <span style="color: rgb(89, 89, 89);">
                              <span data-custom-class="body_text">
                                <span style="color: rgb(89, 89, 89);">
                                    <span data-custom-class="body_text">
                                      <span style="color: rgb(89, 89, 89);">
                                          <span data-custom-class="body_text">
                                            <bdt class="statement-end-if-in-editor"></bdt>
                                          </span>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <p style="font-size: 15px; line-height: 1.5;">
        <bdt class="block-component"></bdt>
        </span></span></span></span></span></span></span></span></span></span></span></li>
      </ul>
      <p style="font-size: 15px; line-height: 1.5;">
        <bdt class="block-component"></bdt>
      </p>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span style="color: rgb(89, 89, 89);">
                  <span style="color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        <strong>To request feedback. </strong>We may process your information when necessary to request feedback and to contact you about your use of our Services.
                        <span style="color: rgb(89, 89, 89);">
                          <span style="color: rgb(89, 89, 89);">
                              <span data-custom-class="body_text">
                                <span style="color: rgb(89, 89, 89);">
                                    <span data-custom-class="body_text">
                                      <span style="color: rgb(89, 89, 89);">
                                          <span data-custom-class="body_text">
                                            <bdt class="statement-end-if-in-editor"></bdt>
                                          </span>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></bdt>
      </span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"></bdt>
      </span></span></span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"></bdt>
      </span></span></span></li></ul>
      <div style="line-height: 1.5;">
      <span style="font-size: 15px;">
        <bdt class="block-component"><span data-custom-class="body_text"></bdt>
        </span>
      </span>
      </li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt>
      </span></span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;"><strong>To protect our Services.</strong> We may process your information as part of our efforts to keep our Services safe and secure, including fraud monitoring and prevention.</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;"><strong>To identify usage trends.</strong> We may process information about how you use our Services to better understand how they are being used so we can improve them.</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt>
      </span></span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt>
      </span></span></li></ul>
      <div style="line-height: 1.5;">
      <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt>
      </span></span></li></ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;"><strong>To save or protect an individual's vital interest.</strong> We may process your information when necessary to save or protect an individual’s vital interest, such as to prevent harm.</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="forloop-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">
                  <bdt class="question"><strong>To provide user-to-user health info</strong></bdt>
                  <strong>.</strong>
                  <bdt class="question">A user can have their health info sent to a docotr, nurse, or other trusted healthcare provider and vis versa </bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="forloop-component"></bdt>
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="legalbases" style="line-height: 1.5;">
        <strong>
            <span style="font-size: 15px;">
              <span data-custom-class="heading_1">
                  <h2>3. WHAT LEGAL BASES DO WE RELY ON TO PROCESS YOUR INFORMATION?</h2>
              </span>
            </span>
        </strong>
        <em>
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">
                  <strong>In Short: </strong>We only process your personal information when we believe it is necessary and we have a valid legal reason (i.e.
                  <bdt class="block-component"></bdt>
                  ,
                  <bdt class="statement-end-if-in-editor"></bdt>
                  legal basis) to do so under applicable law, like with your consent, to comply with laws, to provide you with services to enter into or
                  <bdt class="block-component"></bdt>
                  fulfill
                  <bdt class="statement-end-if-in-editor"></bdt>
                  our contractual obligations, to protect your rights, or to
                  <bdt class="block-component"></bdt>
                  fulfill
                  <bdt class="statement-end-if-in-editor"></bdt>
                  our legitimate business interests.
              </span>
            </span>
        </em>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><em><span style="font-size: 15px;"><span data-custom-class="body_text"><strong><u>If you are located in the EU or UK, this section applies to you.</u></strong></span></span></em></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">The General Data Protection Regulation (GDPR) and UK GDPR require us to explain the valid legal bases we rely on in order to process your personal information. As such, we may rely on the following legal bases to process your personal information:</span></span></div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">
                  <strong>Consent. </strong>We may process your information if you have given us permission (i.e.
                  <bdt class="block-component"></bdt>
                  ,
                  <bdt class="statement-end-if-in-editor"></bdt>
                  consent) to use your personal information for a specific purpose. You can withdraw your consent at any time. Learn more about
              </span>
            </span>
            <a data-custom-class="link" href="#withdrawconsent"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">withdrawing your consent</span></span></a><span data-custom-class="body_text">.</span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  <strong>Performance of a Contract.</strong> We may process your personal information when we believe it is necessary to
                  <bdt class="block-component"></bdt>
                  fulfill
                  <bdt class="statement-end-if-in-editor"></bdt>
                  our contractual obligations to you, including providing our Services or at your request prior to entering into a contract with you.
              </span>
            </span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;"><strong>Legitimate Interests.</strong> We may process your information when we believe it is reasonably necessary to achieve our legitimate business interests and those interests do not outweigh your interests and fundamental rights and freedoms. For example, we may process your personal information for some of the purposes described in order to:</span></span></li>
      </ul>
      <div style="line-height: 1.5;">
      <span data-custom-class="body_text">
        <span style="font-size: 15px;">
            <bdt class="block-component"></bdt>
        </span>
      </span>
      </li></ul>
      <div style="line-height: 1.5;">
      <span data-custom-class="body_text">
        <span style="font-size: 15px;">
            <bdt class="block-component"></bdt>
        </span>
      </span>
      </li></ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul style="margin-left: 40px;">
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  <bdt class="block-component"></bdt>
                  Analyze
                  <bdt class="statement-end-if-in-editor"></bdt>
                  how our Services are used so we can improve them to engage and retain users
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
      <span data-custom-class="body_text">
        <span style="font-size: 15px;">
            <bdt class="block-component"></bdt>
        </span>
      </span>
      </li></ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul style="margin-left: 40px;">
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  Diagnose problems and/or prevent fraudulent activities
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul style="margin-left: 40px;">
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  Understand how our users use our products and services so we can improve user experience
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  <strong>Legal Obligations.</strong> We may process your information where we believe it is necessary for compliance with our legal obligations, such as to cooperate with a law enforcement body or regulatory agency, exercise or defend our legal rights, or disclose your information as evidence in litigation in which we are involved.
                  <bdt class="statement-end-if-in-editor"></bdt>
                  <br>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;"><strong>Vital Interests.</strong> We may process your information where we believe it is necessary to protect your vital interests or the vital interests of a third party, such as situations involving potential threats to the safety of any person.</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component">
                  <bdt class="block-component"></bdt>
              </bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;"><strong><u><em>If you are located in Canada, this section applies to you.</em></u></strong></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              We may process your information if you have given us specific permission (i.e.
              <bdt class="block-component"></bdt>
              ,
              <bdt class="statement-end-if-in-editor"></bdt>
              express consent) to use your personal information for a specific purpose, or in situations where your permission can be inferred (i.e.
              <bdt class="block-component"></bdt>
              ,
              <bdt class="statement-end-if-in-editor"></bdt>
              implied consent). You can
            </span>
        </span>
        <a data-custom-class="link" href="#withdrawconsent"><span data-custom-class="body_text"><span style="color: rgb(0, 58, 250); font-size: 15px;">withdraw your consent</span></span></a><span data-custom-class="body_text"><span style="font-size: 15px;"> at any time.</span></span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;">In some exceptional cases, we may be legally permitted under applicable law to process your information without your consent, including, for example:</span></span></div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;">If collection is clearly in the interests of an individual and consent cannot be obtained in a timely way</span></span></li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  For investigations and fraud detection and prevention
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;">For business transactions provided certain conditions are met</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;">If it is contained in a witness statement and the collection is necessary to assess, process, or settle an insurance claim</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text"><span style="font-size: 15px;">For identifying injured, ill, or deceased persons and communicating with next of kin</span></span>
            <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  If we have reasonable grounds to believe an individual has been, is, or may be victim of financial abuse
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  If it is reasonable to expect collection and use with consent would compromise the availability or the accuracy of the information and the collection is reasonable for purposes related to investigating a breach of an agreement or a contravention of the laws of Canada or a province
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  If disclosure is required to comply with a subpoena, warrant, court order, or rules of the court relating to the production of records
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">
                  If it was produced by an individual in the course of their employment, business, or profession and the collection is consistent with the purposes for which the information was produced
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">
                  If the collection is solely for journalistic, artistic, or literary purposes
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              <span data-custom-class="body_text">If the information is publicly available and is specified by the regulations</span>
              <bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span style="font-size: 15px;">
              We may disclose de-identified information for approved research or statistics projects, subject to ethics oversight and confidentiality commitments
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="whoshare" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>4. WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><em>In Short:</em></strong>
                  <em>
                    We may share information in specific situations described in this section and/or with the following
                    <bdt class="block-component"></bdt>
                    third parties.
                  </em>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component">
              </span>
      </div>
      <div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">We <bdt class="block-component"></bdt>may need to share your personal information in the following situations:</span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>Business Transfers.</strong> We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.</span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"><span data-custom-class="body_text"></span></bdt></span></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;"><strong>Business Partners.</strong> We may share your information with our business partners to offer you certain products, services, or promotions.</span></span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><strong>Other Users.</strong> When you share personal information<bdt class="block-component"></bdt> or otherwise interact with public areas of the Services, such personal information may be viewed by all users and may be publicly made available outside the Services in perpetuity.<bdt class="block-component"></bdt> Similarly, other users will be able to view descriptions of your activity, communicate with you within our Services, and view your profile.<bdt class="statement-end-if-in-editor"></bdt></span></span></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><bdt class="block-component"><span data-custom-class="heading_1"><bdt class="block-component"></bdt></span></bdt></span></span></span></span></span></div><div style="line-height: 1.5;"><br></div><div id="cookies" style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span id="control" style="color: rgb(0, 0, 0);"><strong><span data-custom-class="heading_1"><h2>5. DO WE USE COOKIES AND OTHER TRACKING TECHNOLOGIES?</h2></span></strong></span></span></span></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong><em>In Short:</em></strong><em> We may use cookies and other tracking technologies to collect and store your information.</em></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may use cookies and similar tracking technologies (like web beacons and pixels) to gather information when you interact with our Services. Some online tracking technologies help us maintain the security of our Services<bdt class="block-component"></bdt> and your account<bdt class="statement-end-if-in-editor"></bdt>, prevent crashes, fix bugs, save your preferences, and assist with basic site functions.</span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We also permit third parties and service providers to use online tracking technologies on our Services for analytics and advertising, including to help manage and display advertisements, to tailor advertisements to your interests, or to send abandoned shopping cart reminders (depending on your communication preferences). The third parties and service providers use their technology to provide advertising about products and services tailored to your interests which may appear either on our Services or on other websites.</span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">To the extent these online tracking technologies are deemed to be a <bdt class="block-component"></bdt>"sale"/"sharing"<bdt class="statement-end-if-in-editor"></bdt> (which includes targeted advertising, as defined under the applicable laws) under applicable US state laws, you can opt out of these online tracking technologies by submitting a request as described below under section <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span><span data-custom-class="body_text"><a data-custom-class="link" href="#uslaws"><span style="color: rgb(0, 58, 250); font-size: 15px;">DO UNITED STATES RESIDENTS HAVE SPECIFIC PRIVACY RIGHTS?</span></a></span><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span><bdt class="statement-end-if-in-editor"></bdt></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Specific information about how we use such technologies and how you can refuse certain cookies is set out in our Cookie Notice<span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span>: <span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text"><bdt class="question"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com/cookie-policy">https://www.safehemo.com/cookie-policy</a></bdt></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><bdt class="block-component"></bdt>.</span></span></span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></span></span></span></span></span><span style="font-size: 15px;"><bdt class="block-component"></bdt></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span><bdt class="block-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></span></span></span></span></span></span></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div id="inforetain" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>6. HOW LONG DO WE KEEP YOUR INFORMATION?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><em>In Short: </em></strong>
                  <em>
                    We keep your information for as long as necessary to
                    <bdt class="block-component"></bdt>
                    fulfill
                    <bdt class="statement-end-if-in-editor"></bdt>
                    the purposes outlined in this Privacy Notice unless otherwise required by law.
                  </em>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  We will only keep your personal information for as long as it is necessary for the purposes set out in this Privacy Notice, unless a longer retention period is required or permitted by law (such as tax, accounting, or other legal requirements).
                  <bdt class="block-component"></bdt>
                  No purpose in this notice will require us keeping your personal information for longer than
                  <span style="font-size: 15px;">
                    <span style="color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
                  <bdt class="block-component"></bdt>
                  the period of time in which users have an account with us
                  <bdt class="block-component"></bdt>
                  <span style="font-size: 15px;">
                    <span style="color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <bdt class="else-block"></bdt>
                        </span>
                    </span>
                  </span>
                  .
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  When we have no ongoing legitimate business need to process your personal information, we will either delete or
                  <bdt class="block-component"></bdt>
                  anonymize
                  <bdt class="statement-end-if-in-editor"></bdt>
                  such information, or, if this is not possible (for example, because your personal information has been stored in backup archives), then we will securely store your personal information and isolate it from any further processing until deletion is possible.
                  <span style="color: rgb(89, 89, 89);">
                    <bdt class="block-component"></bdt>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="infosafe" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>7. HOW DO WE KEEP YOUR INFORMATION SAFE?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><em>In Short: </em></strong>
                  <em>
                    We aim to protect your personal information through a system of
                    <bdt class="block-component"></bdt>
                    organizational
                    <bdt class="statement-end-if-in-editor"></bdt>
                    and technical security measures.
                  </em>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  We have implemented appropriate and reasonable technical and
                  <bdt class="block-component"></bdt>
                  organizational
                  <bdt class="statement-end-if-in-editor"></bdt>
                  security measures designed to protect the security of any personal information we process. However, despite our safeguards and efforts to secure your information, no electronic transmission over the Internet or information storage technology can be guaranteed to be 100% secure, so we cannot promise or guarantee that hackers, cybercriminals, or other
                  <bdt class="block-component"></bdt>
                  unauthorized
                  <bdt class="statement-end-if-in-editor"></bdt>
                  third parties will not be able to defeat our security and improperly collect, access, steal, or modify your information. Although we will do our best to protect your personal information, transmission of personal information to and from our Services is at your own risk. You should only access the Services within a secure environment.
                  <span style="color: rgb(89, 89, 89);">
                    <bdt class="statement-end-if-in-editor"></bdt>
                  </span>
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <span data-custom-class="body_text">
                        <bdt class="block-component"></bdt>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="privacyrights" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>8. WHAT ARE YOUR PRIVACY RIGHTS?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><em>In Short:</em></strong>
                  <em>
                    <span style="color: rgb(89, 89, 89);">
                        <span style="font-size: 15px;">
                          <span data-custom-class="body_text">
                              <em>
                                <bdt class="block-component"></bdt>
                              </em>
                          </span>
                        </span>
                    </span>
                    <bdt class="block-component"></bdt>
                    Depending on your state of residence in the US or in
                    <bdt class="else-block"></bdt>
                    some regions, such as
                    <bdt class="block-component"></bdt>
                    the European Economic Area (EEA), United Kingdom (UK), Switzerland, and Canada
                    <bdt class="block-component"></bdt>
                    , you have rights that allow you greater access to and control over your personal information.
                    <span style="color: rgb(89, 89, 89);">
                        <span style="font-size: 15px;">
                          <span data-custom-class="body_text">
                              <em>
                                <bdt class="statement-end-if-in-editor"></bdt>
                              </em>
                          </span>
                        </span>
                    </span>
                    You may review, change, or terminate your account at any time, depending on your country, province, or state of residence.
                  </em>
                  <span style="color: rgb(89, 89, 89);">
                    <span style="font-size: 15px;">
                        <bdt class="block-component"></bdt>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  In some regions (like
                  <bdt class="block-component"></bdt>
                  the EEA, UK, Switzerland, and Canada
                  <bdt class="block-component"></bdt>
                  ), you have certain rights under applicable data protection laws. These may include the right (i) to request access and obtain a copy of your personal information, (ii) to request rectification or erasure; (iii) to restrict the processing of your personal information; (iv) if applicable, to data portability; and (v) not to be subject to automated decision-making.
                  <bdt class="block-component"></bdt>
                  If a decision that produces legal or similarly significant effects is made solely by automated means, we will inform you, explain the main factors, and offer a simple way to request human review.
                  <bdt class="statement-end-if-in-editor"></bdt>
                  In certain circumstances, you may also have the right to object to the processing of your personal information. You can make such a request by contacting us by using the contact details provided in the section
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </span>
        <a data-custom-class="link" href="#contact"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span data-custom-class="body_text">HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</span></span></span></a>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
                  below.
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  We will consider and act upon any request in accordance with applicable data protection laws.
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"> </span></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If you are located in the EEA or UK and you believe we are unlawfully processing your personal information, you also have the right to complain to your <span style="font-size: 15px;"><span style="color: rgb(0, 58, 250);"><span data-custom-class="body_text"><span style="color: rgb(0, 58, 250);"><span data-custom-class="body_text"><a data-custom-class="link" href="https://ec.europa.eu/justice/data-protection/bodies/authorities/index_en.htm" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Member State data protection authority</span></a></span></span></span></span></span> or </span></span></span><a data-custom-class="link" href="https://ico.org.uk/make-a-complaint/data-protection-complaints/data-protection-complaints/" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span data-custom-class="body_text">UK data protection authority</span></span></span></a><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">.</span></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If you are located in Switzerland, you may contact the <span style="font-size: 15px;"><span style="color: rgb(0, 58, 250);"><span data-custom-class="body_text"><span style="color: rgb(0, 58, 250);"><span data-custom-class="body_text"><span style="color: rgb(0, 58, 250); font-size: 15px;"><a data-custom-class="link" href="https://www.edoeb.admin.ch/edoeb/en/home.html" rel="noopener noreferrer" target="_blank">Federal Data Protection and Information Commissioner</a></span></span></span></span></span></span>.</span></span></span></div>
      <div style="line-height: 1.5;"><br></div>
      <div id="withdrawconsent" style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><u>Withdrawing your consent:</u></strong> If we are relying on your consent to process your personal information,
                  <bdt class="block-component"></bdt>
                  which may be express and/or implied consent depending on the applicable law,
                  <bdt class="statement-end-if-in-editor"></bdt>
                  you have the right to withdraw your consent at any time. You can withdraw your consent at any time by contacting us by using the contact details provided in the section
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </span>
        <a data-custom-class="link" href="#contact"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span data-custom-class="body_text">HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</span></span></span></a>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
                  below
                  <bdt class="block-component"></bdt>
                  or updating your preferences
                  <bdt class="statement-end-if-in-editor"></bdt>
                  .
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              However, please note that this will not affect the lawfulness of the processing before its withdrawal nor,
              <bdt class="block-component"></bdt>
              when applicable law allows,
              <bdt class="statement-end-if-in-editor"></bdt>
              will it affect the processing of your personal information conducted in reliance on lawful processing grounds other than consent.
              <bdt class="block-component"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <strong><u>Opting out of marketing and promotional communications:</u></strong><strong> </strong>You can unsubscribe from our marketing and promotional communications at any time by
              <bdt class="block-component"></bdt>
              clicking on the unsubscribe link in the emails that we send,
              <bdt class="statement-end-if-in-editor"></bdt>
              <bdt class="block-component"></bdt>
              replying
              <bdt class="block-component"></bdt>
              "STOP" or "UNSUBSCRIBE"
              <bdt class="statement-end-if-in-editor"></bdt>
              to the SMS messages that we send,
              <bdt class="statement-end-if-in-editor"></bdt>
              <bdt class="block-component"></bdt>
              or by contacting us using the details provided in the section
              <bdt class="block-component"></bdt>
              "
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
        <a data-custom-class="link" href="#contact"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text">HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</span></span></a>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="block-component"></bdt>
              "
              <bdt class="statement-end-if-in-editor"></bdt>
              below. You will then be removed from the marketing lists. However, we may still communicate with you — for example, to send you service-related messages that are necessary for the administration and use of your account, to respond to service requests, or for other non-marketing purposes.
            </span>
        </span>
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;"><span data-custom-class="body_text">No mobile information will be shared with third parties or affiliates for marketing or promotional purposes. Information sharing to subcontractors in support services, such as customer service, is permitted. All other use case categories exclude text messaging originator opt-in data and consent; this information will not be shared with third parties.</span></span>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt>
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              <bdt class="statement-end-if-in-editor"></bdt>
            </span>
        </span>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <span style="font-size: 15px;">
            <span data-custom-class="heading_2">
              <strong>
                  <h3>Account Information</h3>
              </strong>
            </span>
        </span>
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              If you would at any time like to review or change the information in your account or terminate your account, you can:
              <bdt class="forloop-component"></bdt>
            </span>
        </span>
      </div>
      <ul>
        <li data-custom-class="body_text" style="line-height: 1.5;">
            <span data-custom-class="body_text">
              <span style="font-size: 15px;">
                  <bdt class="question">Contact us using the contact information provided.</bdt>
              </span>
            </span>
        </li>
      </ul>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              <bdt class="forloop-component"></bdt>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;"><span data-custom-class="body_text">Upon your request to terminate your account, we will deactivate or delete your account and information from our active databases. However, we may retain some information in our files to prevent fraud, troubleshoot problems, assist with any investigations, enforce our legal terms and/or comply with applicable legal requirements.</span></span>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <span style="font-size: 15px;">
                    <span style="color: rgb(89, 89, 89);">
                        <span style="font-size: 15px;">
                          <span style="color: rgb(89, 89, 89);">
                              <span data-custom-class="body_text">
                                <span style="font-size: 15px;">
                                    <span style="color: rgb(89, 89, 89);">
                                      <bdt class="block-component"></bdt>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><u>Cookies and similar technologies:</u></strong> Most Web browsers are set to accept cookies by default. If you prefer, you can usually choose to set your browser to remove cookies and to reject cookies. If you choose to remove cookies or reject cookies, this could affect certain features or services of our Services.
                  <bdt class="block-component">
                  <span style="font-size: 15px;">
                    <span style="color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
                  For further information, please see our Cookie Notice:
                  <span style="font-size: 15px;">
                    <span style="color: rgb(89, 89, 89);">
                        <span data-custom-class="body_text">
                          <span style="color: rgb(0, 58, 250);">
                              <bdt class="question"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com/cookie-policy">https://www.safehemo.com/cookie-policy</a></bdt>
                          </span>
                          .
                          <bdt class="block-component"></bdt>
                          <span style="font-size: 15px;">
                              <span style="color: rgb(89, 89, 89);">
                                <span style="font-size: 15px;">
                                    <span style="color: rgb(89, 89, 89);">
                                      <span style="font-size: 15px;">
                                          <span style="color: rgb(89, 89, 89);">
                                            <bdt class="statement-end-if-in-editor"></bdt>
                                          </span>
                                      </span>
                                    </span>
                                </span>
                              </span>
                          </span>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div style="line-height: 1.5;">
        <span data-custom-class="body_text">
            <span style="font-size: 15px;">
              If you have questions or comments about your privacy rights, you may email us at
              <bdt class="question noTranslate"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a></bdt>
              .
            </span>
        </span>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"><span data-custom-class="body_text"></span></span></bdt>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="DNT" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>9. CONTROLS FOR DO-NOT-TRACK FEATURES</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  Most web browsers and some mobile operating systems and mobile applications include a Do-Not-Track (
                  <bdt class="block-component"></bdt>
                  "DNT"
                  <bdt class="statement-end-if-in-editor"></bdt>
                  ) feature or setting you can activate to signal your privacy preference not to have data about your online browsing activities monitored and collected. At this stage, no uniform technology standard for
                  <bdt class="block-component"></bdt>
                  recognizing
                  <bdt class="statement-end-if-in-editor"></bdt>
                  and implementing DNT signals has been
                  <bdt class="block-component"></bdt>
                  finalized
                  <bdt class="statement-end-if-in-editor"></bdt>
                  . As such, we do not currently respond to DNT browser signals or any other mechanism that automatically communicates your choice not to be tracked online. If a standard for online tracking is adopted that we must follow in the future, we will inform you about that practice in a revised version of this Privacy Notice.
              </span>
            </span>
        </span>
        <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
      </div>
      <div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px;">
            <span data-custom-class="body_text">
              California law requires us to let you know how we respond to web browser DNT signals. Because there currently is not an industry or legal standard for
              <bdt class="block-component"></bdt>
              recognizing
              <bdt class="statement-end-if-in-editor"></bdt>
              or
              <bdt class="block-component"></bdt>
              honoring
              <bdt class="statement-end-if-in-editor"></bdt>
              DNT signals, we do not respond to them at this time.
            </span>
        </span>
        <bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt>
      </div>
      <div style="line-height: 1.5;">
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <div id="uslaws" style="line-height: 1.5;">
        <span style="color: rgb(127, 127, 127);">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span id="control" style="color: rgb(0, 0, 0);">
                        <strong>
                          <span data-custom-class="heading_1">
                              <h2>10. DO UNITED STATES RESIDENTS HAVE SPECIFIC PRIVACY RIGHTS?</h2>
                          </span>
                        </strong>
                    </span>
                  </span>
              </span>
            </span>
        </span>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <strong><em>In Short: </em></strong>
                  <em>
                    If you are a resident of
                    <bdt class="block-component"></bdt>
                    California, Colorado, Connecticut, Delaware, Florida, Indiana, Iowa, Kentucky, Maryland, Minnesota, Montana, Nebraska, New Hampshire, New Jersey, Oregon, Rhode Island, Tennessee, Texas, Utah, or Virginia
                    <bdt class="else-block"></bdt>
                    , you may have the right to request access to and receive details about the personal information we maintain about you and how we have processed it, correct inaccuracies, get a copy of, or delete your personal information. You may also have the right to withdraw your consent to our processing of your personal information. These rights may be limited in some circumstances by applicable law. More information is provided below.
                  </em>
              </span>
              <strong>
                  <span data-custom-class="heading_2">
                    <h3>Categories of Personal Information We Collect</h3>
                  </span>
              </strong>
              <span data-custom-class="body_text">
                  The table below shows the categories of personal information we have collected in the past twelve (12) months. The table includes illustrative examples of each category and does not reflect the personal information we collect from you. For a comprehensive inventory of all personal information we process, please refer to the section
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </span>
        <a data-custom-class="link" href="#infocollect"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span data-custom-class="body_text"><span data-custom-class="link">WHAT INFORMATION DO WE COLLECT?</span></span></span></span></a>
        <span style="font-size: 15px; color: rgb(89, 89, 89);">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
                  "
                  <bdt class="statement-end-if-in-editor"></bdt>
              </span>
            </span>
        </span>
      </div>
      <div style="line-height: 1.5;"><br></div>
      <table style="width: 100%;">
        <thead>
            <tr>
              <th style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black; text-align: left;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong>Category</strong></span></span></span></th>
              <th style="width: 51.4385%; border-top: 1px solid black; border-right: 1px solid black; text-align: left;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong>Examples</strong></span></span></span></th>
              <th style="width: 14.9084%; border-right: 1px solid black; border-top: 1px solid black; text-align: center; text-align: left;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong>Collected</strong></span></span></span></th>
            </tr>
        </thead>
        <tbody>
            <tr>
              <td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">A. Identifiers</span></span></span></div>
              </td>
              <td style="width: 51.4385%; border-top: 1px solid black; border-right: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Contact details, such as real name, alias, postal address, telephone or mobile contact number, unique personal identifier, online identifier, Internet Protocol address, email address, and account name</span></span></span></div>
              </td>
              <td style="width: 14.9084%; text-align: center; vertical-align: middle; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><br></div>
                  <div style="line-height: 1.5;">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <bdt class="block-component">
                                <bdt class="block-component"></bdt>
                              </bdt>
                              YES
                              <bdt class="else-block">
                              <bdt class="block-component"></bdt>
                          </span>
                        </span>
                    </span>
                  </div>
                  <div style="line-height: 1.5;"><br></div>
              </td>
            </tr>
        </tbody>
      </table>
      <div style="line-height: 1.5;">
        <bdt class="block-component"></bdt>
      </div>
      <table style="width: 100%;">
        <tbody>
            <tr>
              <td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">B. Personal information as defined in the California Customer Records statute</span></span></span></div>
              </td>
              <td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Name, contact information, education, employment, employment history, and financial information</span></span></span></div>
              </td>
              <td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><br></div>
                  <div style="line-height: 1.5;">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <bdt class="forloop-component">
                              <bdt class="block-component">
                                <bdt class="block-component"></bdt>
                                YES
                                <bdt class="block-component"></bdt>
                              </bdt>
                          </span>
                        </span>
                    </span>
                  </div>
                  <div style="line-height: 1.5;"><br></div>
              </td>
            </tr>
        </tbody>
      </table>
      <div style="line-height: 1.5;">
        <bdt class="block-component"></bdt>
      </div>
      <table style="width: 100%;">
        <tbody>
            <tr>
              <td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <bdt class="block-component"></bdt>
                              C
                              <bdt class="else-block"></bdt>
                              . Protected classification characteristics under state or federal law
                          </span>
                        </span>
                    </span>
                  </div>
              </td>
              <td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Gender, age, date of birth, race and ethnicity, national origin, marital status, and other demographic data</span></span></span></div>
              </td>
              <td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><br></div>
                  <div data-custom-class="body_text" style="line-height: 1.5;">
                    <bdt class="forloop-component">
                    <span data-custom-class="body_text">
                        <bdt class="block-component"></bdt>
                        <bdt class="block-component"></bdt>
                        YES
                        <bdt class="else-block"></bdt>
                        <bdt class="block-component">
                    </span>
                    </bdt>
                  </div>
                  <div style="line-height: 1.5;"><br></div>
              </td>
            </tr>
            <tr>
              <td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <bdt class="block-component"></bdt>
                              D
                              <bdt class="else-block"></bdt>
                              . Commercial information
                          </span>
                        </span>
                    </span>
                  </div>
              </td>
              <td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Transaction information, purchase history, financial details, and payment information</span></span></span></div>
              </td>
              <td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><br></div>
                  <div data-custom-class="body_text" style="line-height: 1.5;">
                    <bdt class="forloop-component">
                    <span data-custom-class="body_text">
                        <bdt class="block-component"></bdt>
                        <bdt class="block-component"></bdt>
                        NO
                        <bdt class="statement-end-if-in-editor">
                        <bdt class="block-component">
                    </span>
                    </bdt>
                  </div>
                  <div style="line-height: 1.5;"><br></div>
              </td>
            </tr>
            <tr>
              <td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="font-size: 15px; color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">
                              <bdt class="block-component"></bdt>
                              E
                              <bdt class="else-block"></bdt>
                              . Biometric information
                          </span>
                        </span>
                    </span>
                  </div>
              </td>
              <td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Fingerprints and voiceprints</span></span></span></div>
              </td>
              <td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;">
                  <div style="line-height: 1.5;"><br></div>
                  <div data-custom-class="body_text" style="line-height: 1.5;">
                    <bdt class="forloop-component">
                    <span data-custom-class="body_text">
                        <bdt class="block-component">
                          <bdt class="block-component">YES</bdt>
                          <bdt class="block-component">
                    </span>
                    </bdt>
                  </div>
                  <div style="line-height: 1.5;"><br></div>
              </td>
            </tr>
            <tr><td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>F<bdt class="else-block"></bdt>. Internet or other similar network activity</span></span></span></div></td><td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Browsing history, search history, online <bdt class="block-component"></bdt>behavior<bdt class="statement-end-if-in-editor"></bdt>, interest data, and interactions with our and other websites, applications, systems, and advertisements</span></span></span></div></td><td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><bdt class="forloop-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>NO<bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>G<bdt class="else-block"></bdt>. Geolocation data</span></span></span></div></td><td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Device location</span></span></span></div></td><td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><bdt class="forloop-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>YES<bdt class="else-block"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>H<bdt class="else-block"></bdt>. Audio, electronic, sensory, or similar information</span></span></span></div></td><td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Images and audio, video or call recordings created in connection with our business activities</span></span></span></div></td><td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><bdt class="forloop-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>YES<bdt class="else-block"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="width: 33.8274%; border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>I<bdt class="else-block"></bdt>. Professional or employment-related information</span></span></span></div></td><td style="width: 51.4385%; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Business contact details in order to provide you our Services at a business level or job title, work history, and professional qualifications if you apply for a job with us</span></span></span></div></td><td style="width: 14.9084%; text-align: center; border-right: 1px solid black; border-top: 1px solid black;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><bdt class="forloop-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>NO<bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="border-left: 1px solid black; border-right: 1px solid black; border-top: 1px solid black; width: 33.8274%;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>J<bdt class="else-block"></bdt>. Education Information</span></span></span></div></td><td style="border-right: 1px solid black; border-top: 1px solid black; width: 51.4385%;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Student records and directory information</span></span></span></div></td><td style="text-align: center; border-right: 1px solid black; border-top: 1px solid black; width: 14.9084%;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><bdt class="forloop-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>NO<bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></span></bdt></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="border-width: 1px; border-color: black; border-style: solid; width: 33.8274%;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>K<bdt class="else-block"></bdt>. Inferences drawn from collected personal information</span></span></span></div></td><td style="border-bottom: 1px solid black; border-top: 1px solid black; border-right: 1px solid black; width: 51.4385%;"><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Inferences drawn from any of the collected personal information listed above to create a profile or summary about, for example, an individual’s preferences and characteristics</span></span></span></div></td><td style="text-align: center; border-right: 1px solid black; border-bottom: 1px solid black; border-top: 1px solid black; width: 14.9084%;"><div style="line-height: 1.5;"><br></div><div data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>NO<span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></span></span></span></div><div style="line-height: 1.5;"><br></div></td></tr><tr><td style="border-left: 1px solid black; border-right: 1px solid black; border-bottom: 1px solid black; line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>L<bdt class="else-block"></bdt>. Sensitive personal Information</span></td><td style="border-right: 1px solid black; border-bottom: 1px solid black; line-height: 1.5;"><bdt class="block-component"><span data-custom-class="body_text"></span></bdt><span data-custom-class="body_text"><bdt class="forloop-component"></bdt><bdt class="block-component"></bdt><bdt class="question">Account login information</bdt><bdt class="else-block"></bdt><bdt class="forloop-component"></bdt><bdt class="block-component"></bdt>, <bdt class="question">biometric data</bdt><bdt class="else-block"></bdt><bdt class="forloop-component"></bdt><bdt class="block-component"></bdt>, <bdt class="question">health data</bdt><bdt class="else-block"></bdt><bdt class="forloop-component"></bdt><bdt class="block-component"></bdt>, <bdt class="question">contents of email or text messages</bdt><bdt class="else-block"></bdt><bdt class="forloop-component"></bdt><bdt class="block-component"></bdt> and <bdt class="question">precise geolocation</bdt><bdt class="statement-end-if-in-editor"></bdt><bdt class="forloop-component"></bdt></span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></td><td style="border-right: 1px solid black; border-bottom: 1px solid black;"><div data-empty="true" style="text-align: center;"><br></div><div data-custom-class="body_text" data-empty="true" style="text-align: center; line-height: 1.5;"><bdt class="block-component"><span data-custom-class="body_text"></span></bdt><span data-custom-class="body_text">YES<bdt class="else-block"></span></bdt></div><div data-empty="true" style="text-align: center;"><br></div></td></tr>
        </tbody>
      </table>
      <div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">We only collect sensitive personal information, as defined by applicable privacy laws or the purposes allowed by law or with your consent. Sensitive personal information may be used, or disclosed to a service provider or contractor, for additional, specified purposes. You may have the right to limit the use or disclosure of your sensitive personal information.<bdt class="block-component"></bdt></span><bdt class="statement-end-if-in-editor"></bdt></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">We may also collect other personal information outside of these categories through instances where you interact with us in person, online, or by phone or mail in the context of:</span><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Receiving help through our customer support channels;<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text"><span style="font-size: 15px;">Participation in customer surveys or contests; and<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text"><span style="font-size: 15px;">Facilitation in the delivery of our Services and to respond to your inquiries.</span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span data-custom-class="body_text"></span></bdt><span data-custom-class="body_text">We will use and retain the collected personal information as needed to provide the Services or for:<bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category A - <bdt class="question">As long as the user has an account with us</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"><bdt class="block-component"></bdt></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category B - <bdt class="question">As long as the user has an account with us</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category <bdt class="block-component"></bdt>C<bdt class="else-block"></bdt> - <bdt class="question">1 year</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category <bdt class="block-component"></bdt>E<bdt class="else-block"></bdt> - <bdt class="question">1 year</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category <bdt class="block-component"></bdt>G<bdt class="else-block"></bdt> - <bdt class="question">1 year</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category <bdt class="block-component"></bdt>H<bdt class="else-block"></bdt> - <bdt class="question">1 year</bdt><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></li></ul><div style="line-height: 1.5;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span data-custom-class="body_text">Category <bdt class="block-component"></bdt>L<bdt class="else-block"></bdt> - <bdt class="question">1 year</bdt><bdt class="statement-end-if-in-editor"></bdt></span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></li></ul><div style="line-height: 1.5;"><strong><span style="font-size: 15px;"><span data-custom-class="heading_2"><h3>Sources of Personal Information</h3></span></span></strong><span style="font-size: 15px;"><span data-custom-class="body_text">Learn more about the sources of personal information we collect in <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span><span style="color: rgb(0, 58, 250);"><span data-custom-class="body_text"><a data-custom-class="link" href="#infocollect"><span style="color: rgb (0, 58, 250); font-size: 15px;">WHAT INFORMATION DO WE COLLECT?</span></a></span></span><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>"</span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><strong><span data-custom-class="heading_2"><h3>How We Use and Share Personal Information</h3></span></strong></span></span><span data-custom-class="body_text" style="font-size: 15px;"><bdt class="block-component"></bdt>Learn more about how we use your personal information in the section, <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span><a data-custom-class="link" href="#infouse"><span style="color: rgb(0, 58, 250); font-size: 15px;">HOW DO WE PROCESS YOUR INFORMATION?</span></a><span data-custom-class="body_text" style="font-size: 15px;"><bdt class="block-component"></bdt>"</span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text" style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></bdt></bdt></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><strong>Will your information be shared with anyone else?</strong></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may disclose your personal information with our service providers pursuant to a written contract between us and each service provider. Learn more about how we disclose personal information to in the section, <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span></span><a data-custom-class="link" href="#whoshare"><span style="font-size: 15px; color: rgb(0, 58, 250);"><span style="font-size: 15px; color: rgb(0, 58, 250);">WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?</span></span></a><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may use your personal information for our own business purposes, such as for undertaking internal research for technological development and demonstration. This is not considered to be <bdt class="block-component"></bdt>"selling"<bdt class="statement-end-if-in-editor"></bdt> of your personal information.<span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We have not disclosed, sold, or shared any personal information to third parties for a business or commercial purpose in the preceding twelve (12) months. We<span style="color: rgb(89, 89, 89);"> </span>will not sell or share personal information in the future belonging to website visitors, users, and other consumers.<span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span><bdt class="block-component"></bdt></span></span></span></span></span></span></span></span></span></bdt></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span></span><span data-custom-class="body_text"><span style="color: rgb(0, 0, 0);"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><strong><span data-custom-class="heading_2"><h3>Your Rights</h3></span></strong><span data-custom-class="body_text">You have rights under certain US state data protection laws. However, these rights are not absolute, and in certain cases, we may decline your request as permitted by law. These rights include:</span><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to know</strong> whether or not we are processing your personal data<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to access </strong>your personal data<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to correct </strong>inaccuracies in your personal data<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to request</strong> the deletion of your personal data<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to obtain a copy </strong>of the personal data you previously shared with us<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to non-discrimination</strong> for exercising your rights<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><strong>Right to opt out</strong> of the processing of your personal data if it is used for targeted advertising<bdt class="block-component"></bdt> (or sharing as defined under California’s privacy law)<bdt class="statement-end-if-in-editor"></bdt>, the sale of personal data, or profiling in furtherance of decisions that produce legal or similarly significant effects (<bdt class="block-component"></bdt>"profiling"<bdt class="statement-end-if-in-editor"></bdt>)<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">Depending upon the state where you live, you may also have the following rights:</span><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to access the categories of personal data being processed (as permitted by applicable law, including the privacy law in Minnesota)<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to obtain a list of the categories of third parties to which we have disclosed personal data (as permitted by applicable law, including the privacy law in<bdt class="block-component"></bdt> California, Delaware, and Maryland<bdt class="else-block"></bdt><bdt class="block-component"></bdt>)<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to obtain a list of specific third parties to which we have disclosed personal data (as permitted by applicable law, including the privacy law in<bdt class="block-component"></bdt> Minnesota and Oregon<bdt class="else-block"></bdt>)</span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5; font-size: 15px;">Right to obtain a list of third parties to which we have sold personal data (as permitted by applicable law, including the privacy law in Connecticut)<bdt class="statement-end-if-in-editor"></bdt></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to review, understand, question, and depending on where you live, correct how personal data has been profiled (as permitted by applicable law, including the privacy law in <bdt class="block-component"></bdt>Connecticut and Minnesota<bdt class="else-block"></bdt>)<bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to limit use and disclosure of sensitive personal data (as permitted by applicable law, including the privacy law in California)</span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt></li></ul><div style="line-height: 1.5;"><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;">Right to opt out of the collection of sensitive data and personal data collected through the operation of a voice or facial recognition feature (as permitted by applicable law, including the privacy law in Florida)</span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"></bdt></span><strong><span style="font-size: 15px;"><span data-custom-class="heading_2"><h3>How to Exercise Your Rights</h3></span></span></strong><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">To exercise these rights, you can contact us <bdt class="block-component"></bdt>by visiting <span style="color: rgb(0, 58, 250);"><bdt class="question"><a target="_blank" data-custom-class="link" href="https://wyrfihqus37.typeform.com/to/jMjKXzfd">https://wyrfihqus37.typeform.com/to/jMjKXzfd</a></bdt></span>, <bdt class="else-block"></bdt></span><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>by emailing us at <bdt class="question"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a></bdt>, <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt></span><span data-custom-class="body_text"><bdt class="block-component"></bdt>by visiting <span style="color: rgb(0, 58, 250);"><bdt class="question"><a target="_blank" data-custom-class="link" href="https://wyrfihqus37.typeform.com/to/jMjKXzfd">https://wyrfihqus37.typeform.com/to/jMjKXzfd</a></bdt></span>, <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt></bdt></span></span></span></span></span></span></span></span></span></span></span></span><span data-custom-class="body_text">or by referring to the contact details at the bottom of this document.</span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">Under certain US state data protection laws, you can designate an <bdt class="block-component"></bdt>authorized<bdt class="statement-end-if-in-editor"></bdt> agent to make a request on your behalf. We may deny a request from an <bdt class="block-component"></bdt>authorized<bdt class="statement-end-if-in-editor"></bdt> agent that does not submit proof that they have been validly <bdt class="block-component"></bdt>authorized<bdt class="statement-end-if-in-editor"></bdt> to act on your behalf in accordance with applicable laws.</span><br><strong><span data-custom-class="heading_2"><h3>Request Verification</h3></span></strong><span data-custom-class="body_text">Upon receiving your request, we will need to verify your identity to determine you are the same person about whom we have the information in our system. We will only use personal information provided in your request to verify your identity or authority to make the request. However, if we cannot verify your identity from the information already maintained by us, we may request that you provide additional information for the purposes of verifying your identity and for security or fraud-prevention purposes.</span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">If you submit the request through an <bdt class="block-component"></bdt>authorized<bdt class="statement-end-if-in-editor"></bdt> agent, we may need to collect additional information to verify your identity before processing your request and the agent will need to provide a written and signed permission from you to submit such request on your behalf.</span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px;"><span data-custom-class="heading_2"><strong><h3>Appeals</h3></strong></span><span data-custom-class="body_text">Under certain US state data protection laws, if we decline to take action regarding your request, you may appeal our decision by emailing us at <bdt class="block-component"></bdt><bdt class="question noTranslate"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a></bdt><bdt class="else-block"></bdt>. We will inform you in writing of any action taken or not taken in response to the appeal, including a written explanation of the reasons for the decisions. If your appeal is denied, you may submit a complaint to your state attorney general.</span><bdt class="statement-end-if-in-editor"></bdt></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span><strong><span data-custom-class="heading_2"><h3>Financial Incentives</h3></span></strong><span data-custom-class="body_text"><bdt class="block-component"></bdt>"Financial incentive"<bdt class="statement-end-if-in-editor"></bdt> means a program, benefit, or other offering, including payments to consumers as compensation, for the disclosure, deletion, sale, or sharing of personal information.</span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">The law permits financial incentives or a price or service difference if it is reasonably related to the value of the consumer’s data. A business must be able to explain how the financial incentive or price or service difference is reasonably related to the value of the consumer’s data. The explanation must include:<span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">a good-faith estimate of the value of the consumer’s data that forms the basis for offering the financial incentive or price or service difference; and<span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(0, 0, 0);"><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(0, 0, 0);"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></span></span></span></span></span></span></span></li></ul><div><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt></span></span></span></span></span></span></span></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">a description of the method the business used to calculate the value of the consumer’s data.<span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="color: rgb(0, 0, 0);"><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(0, 0, 0);"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></span></span></span></span></span></span></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may decide to offer <bdt class="block-component"></bdt>a <bdt class="block-component"></bdt>"bona fide loyalty program"<bdt class="statement-end-if-in-editor"></bdt> under Colorado law<bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt>, or <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt>a <bdt class="block-component"></bdt>"financial incentive"<bdt class="statement-end-if-in-editor"></bdt> under California law<bdt class="statement-end-if-in-editor"></bdt> (e.g.<bdt class="block-component"></bdt>,<bdt class="statement-end-if-in-editor"></bdt> price or service difference) in exchange for the retention, sale, or sharing of a consumer’s personal information.</span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If we decide to offer a financial incentive, we will notify you of such financial incentive and explain the price difference, as well as material terms of the financial incentive or price of service difference, including the categories of personal information that are implicated by the financial incentive or price or service difference.</span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">Under California law, the value of your personal information to us is related to the value of the free or discounted products or services, or other benefits that you obtain or that are provided as part of the applicable program, less the expense related to offering those products, services, and benefits to program participants.</span></span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If you choose to participate in the financial incentive you can withdraw from the financial incentive at any time </span><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>by emailing us at <bdt class="question"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a></bdt>, <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt></span><span data-custom-class="body_text"><bdt class="block-component"></bdt>by visiting <span style="color: rgb(0, 58, 250);"><bdt class="question"><a target="_blank" data-custom-class="link" href="https://wyrfihqus37.typeform.com/to/jMjKXzfd">https://wyrfihqus37.typeform.com/to/jMjKXzfd</a></bdt></span>, <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"><span data-custom-class="body_text"><bdt class="block-component"></bdt></bdt></span></span></span></span></span></span></span></span></span></span></span></span></span></span><span data-custom-class="body_text">or by referring to the contact details at the bottom of this document.</span><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"><bdt class="block-component"></span></bdt></span></span></span></span></span></span></span></span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px;"><strong><span data-custom-class="heading_2"><h3>California <bdt class="block-component"></bdt>"Shine The Light"<bdt class="statement-end-if-in-editor"></bdt> Law</h3></span></strong><span data-custom-class="body_text">California Civil Code Section 1798.83, also known as the <bdt class="block-component"></bdt>"Shine The Light"<bdt class="statement-end-if-in-editor"></bdt> law, permits our users who are California residents to request and obtain from us, once a year and free of charge, information about categories of personal information (if any) we disclosed to third parties for direct marketing purposes and the names and addresses of all third parties with which we shared personal information in the immediately preceding calendar year. If you are a California resident and would like to make such a request, please submit your request in writing to us by using the contact details provided in the section <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span><span data-custom-class="body_text"><a data-custom-class="link" href="#contact"><span style="color: rgb(0, 58, 250); font-size: 15px;">HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</span></a></span><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>"</span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></span><bdt class="statement-end-if-in-editor"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"><bdt class="statement-end-if-in-editor"></bdt></bdt></span></span></span></span></span></span></span></span></span></span></span></bdt></span></span></span></span></span></span></span></span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span id="otherlaws" style="font-size: 15px;"><strong><span data-custom-class="heading_1"><h2>11. DO OTHER REGIONS HAVE SPECIFIC PRIVACY RIGHTS?</h2></span></strong></span><span style="font-size: 15px;"><em><strong><span data-custom-class="body_text">In Short:</span></strong><span data-custom-class="body_text"> You may have additional rights based on the country you reside in.</span></em><bdt class="block-component"></bdt></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"><span data-custom-class="heading_2"></span></bdt><span data-custom-class="heading_2"><h3><strong>Australia</strong><bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt> <strong>and</strong> <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt><strong>New Zealand</strong></h3></span> <bdt class="statement-end-if-in-editor"><span data-custom-class="heading_2"></span></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">We collect and process your personal information under the obligations and conditions set by <bdt class="block-component"></bdt>Australia's Privacy Act 1988<bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt> and <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt>New Zealand's Privacy Act 2020<bdt class="statement-end-if-in-editor"></bdt> (Privacy Act).</span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">This Privacy Notice satisfies the notice requirements defined in<bdt class="block-component"></bdt> both Privacy Acts<bdt class="block-component"></bdt>, in particular: what personal information we collect from you, from which sources, for which purposes, and other recipients of your personal information.</span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">If you do not wish to provide the personal information necessary to <bdt class="block-component"></bdt>fulfill<bdt class="statement-end-if-in-editor"></bdt> their applicable purpose, it may affect our ability to provide our services, in particular:</span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">offer you the products or services that you want</span><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">respond to or help with your requests</span><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">manage your account with us</span><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></div><ul><li data-custom-class="body_text" style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">confirm your identity and protect your account</span><bdt class="statement-end-if-in-editor"></bdt></span></li></ul><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">At any time, you have the right to request access to or correction of your personal information. You can make such a request by contacting us by using the contact details provided in the section <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt><a data-custom-class="link" href="#request"><span style="color: rgb(0, 58, 250);"><span data-custom-class="link">HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?</span></span></a><bdt class="block-component"></bdt>"</span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">If you believe we are unlawfully processing your personal information, you have the right to submit a complaint about <bdt class="block-component"></bdt>a breach of the Australian Privacy Principles to the <a data-custom-class="link" href="https://www.oaic.gov.au/privacy/privacy-complaints/lodge-a-privacy-complaint-with-us" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250);"><span data-custom-class="link">Office of the Australian Information Commissioner</span></span></a><bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt> and <bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt>a breach of New Zealand's Privacy Principles to the <a data-custom-class="link" href="https://www.privacy.org.nz/your-rights/making-a-complaint/" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250);"><span data-custom-class="link">Office of New Zealand Privacy Commissioner</span></span></a><bdt class="statement-end-if-in-editor"></bdt>.</span><bdt class="statement-end-if-in-editor"></bdt></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px;"><strong><span data-custom-class="heading_2"><h3>Republic of South Africa</h3></span></strong><span data-custom-class="body_text">At any time, you have the right to request access to or correction of your personal information. You can make such a request by contacting us by using the contact details provided in the section <bdt class="block-component"></bdt>"<bdt class="statement-end-if-in-editor"></bdt></span></span><span data-custom-class="link"><a href="#request"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="link">HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?</span></span></a></span><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"></bdt>"</span><bdt class="statement-end-if-in-editor"><span data-custom-class="body_text"></span></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text">If you are unsatisfied with the manner in which we address any complaint with regard to our processing of personal information, you can contact the office of the regulator, the details of which are:</span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><br></span></div><div style="line-height: 1.5;"><a data-custom-class="link" href="https://inforegulator.org.za/" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text"><span data-custom-class="link">The Information Regulator (South Africa)</span></span></span></a></div><div style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;">General enquiries: </span><a data-custom-class="link" href="mailto:enquiries@inforegulator.org.za" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="link">enquiries@inforegulator.org.za</span></span></a></span></div><div style="line-height: 1.5;"><span data-custom-class="body_text"><span style="font-size: 15px;">Complaints (complete POPIA/PAIA form 5): </span><a data-custom-class="link" href="mailto:PAIAComplaints@inforegulator.org.za" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="link">PAIAComplaints@inforegulator.org.za</span></span></a><span style="font-size: 15px;"> & </span></span><a data-custom-class="link" href="mailto:POPIAComplaints@inforegulator.org.za" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250); font-size: 15px;"><span data-custom-class="body_text"><span data-custom-class="link">POPIAComplaints@inforegulator.org.za</span></span></span></a><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"></bdt><bdt class="statement-end-if-in-editor"></bdt></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt></div><div style="line-height: 1.5;"><br></div><div id="policyupdates" style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span id="control" style="color: rgb(0, 0, 0);"><strong><span data-custom-class="heading_1"><h2>12. DO WE MAKE UPDATES TO THIS NOTICE?</h2></span></strong></span></span></span></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><em><strong>In Short: </strong>Yes, we will update this notice as necessary to stay compliant with relevant laws.</em></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may update this Privacy Notice from time to time. The updated version will be indicated by an updated <bdt class="block-component"></bdt>"Revised"<bdt class="statement-end-if-in-editor"></bdt> date at the top of this Privacy Notice. If we make material changes to this Privacy Notice, we may notify you either by prominently posting a notice of such changes or by directly sending you a notification. We encourage you to review this Privacy Notice frequently to be informed of how we are protecting your information.</span></span></span></div><div style="line-height: 1.5;"><br></div><div id="contact" style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span id="control" style="color: rgb(0, 0, 0);"><strong><span data-custom-class="heading_1"><h2>13. HOW CAN YOU CONTACT US ABOUT THIS NOTICE?</h2></span></strong></span></span></span></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If you have questions or comments about this notice, you may <span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"><bdt class="block-component"></bdt></bdt>email us at <bdt class="question noTranslate"><a target="_blank" data-custom-class="link" href="mailto:qweliantanner@tutanota.com">qweliantanner@tutanota.com</a> or </bdt><bdt class="statement-end-if-in-editor"><bdt class="block-component"></bdt></bdt></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">contact us by post at:</span></span></span></span></span></span></div><div style="line-height: 1.5;"><br></div><div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><span style="font-size: 15px;"><span style="color: rgb(89, 89, 89);"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="question noTranslate">Qwelian Tanner</bdt></span></span></span></span></span><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt></bdt></span></span></span></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question noTranslate">568 Muse St SW, Atlanta, GA 30310, USA</bdt><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><bdt class="block-component"></bdt></span></span></span></bdt></span></div><div style="line-height: 1.5;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="question">Atlanta</bdt><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><bdt class="block-component"></bdt><bdt class="block-component"></bdt>, <bdt class="question noTranslate">GA</bdt><bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt> <bdt class="question noTranslate">30310</bdt><bdt class="statement-end-if-in-editor"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt><bdt class="block-component"></bdt></span></span></span></span></div><div style="line-height: 1.5;"><span data-custom-class="body_text" style="font-size: 15px;"><bdt class="question noTranslate">United States<span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"></bdt></span></span></span></span></span></span></span></span></span></bdt></span><bdt class="block-component"><span style="font-size: 15px;"><span data-custom-class="body_text"></bdt></span></span></span></bdt><bdt class="statement-end-if-in-editor"></bdt></span></span></span><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><bdt class="statement-end-if-in-editor"><bdt class="block-component"></bdt></bdt></span></span></span></bdt></span></span></span></span><span data-custom-class="body_text"><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89);"><bdt class="statement-end-if-in-editor"><span style="color: rgb(89, 89, 89);"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="block-component"><bdt class="block-component"></bdt></span></span></span></span></span></span><bdt class="block-component"><span style="font-size: 15px;"></span></bdt><span style="font-size: 15px;"><span data-custom-class="body_text"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px;"><span data-custom-class="body_text"><bdt class="statement-end-if-in-editor"><bdt class="block-component"></bdt></span></span></div><div style="line-height: 1.5;"><br></div><div id="request" style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span id="control" style="color: rgb(0, 0, 0);"><strong><span data-custom-class="heading_1"><h2>14. HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?</h2></span></strong></span></span></span></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"><bdt class="block-component"></bdt></bdt>You have the right to request access to the personal information we collect from you, details about how we have processed it, correct inaccuracies, or delete your personal information. You may also have the right to <bdt class="block-component"></bdt>withdraw your consent to our processing of your personal information. These rights may be limited in some circumstances by applicable law. To request to review, update, or delete your personal information, please <bdt class="block-component"></span></bdt><span data-custom-class="body_text">visit: <span style="color: rgb(0, 58, 250);"><bdt class="question"><a target="_blank" data-custom-class="link" href="https://wyrfihqus37.typeform.com/to/jMjKXzfd">https://wyrfihqus37.typeform.com/to/jMjKXzfd</a></bdt></span><bdt class="else-block"></bdt></span></span><span data-custom-class="body_text">.</span></span></span></div><style>
      ul {
      list-style-type: square;
      }
      ul > li > ul {
      list-style-type: circle;
      }
      ul > li > ul > li > ul {
      list-style-type: square;
      }
      ol li {
      font-family: Arial ;
      }
      </style>
      </div>
    """
  end

  defp disclaimer_policy_html do
    """
      <style>
        [data-custom-class='body'], [data-custom-class='body'] * {
        background: transparent !important;
        }
        [data-custom-class='title'], [data-custom-class='title'] * {
        font-family: Arial !important;
        font-size: 26px !important;
        color: #000000 !important;
        }
        [data-custom-class='subtitle'], [data-custom-class='subtitle'] * {
        font-family: Arial !important;
        color: #595959 !important;
        font-size: 14px !important;
        }
        [data-custom-class='heading_1'], [data-custom-class='heading_1'] * {
        font-family: Arial !important;
        font-size: 19px !important;
        color: #000000 !important;
        }
        [data-custom-class='heading_2'], [data-custom-class='heading_2'] * {
        font-family: Arial !important;
        font-size: 17px !important;
        color: #000000 !important;
        }
        [data-custom-class='body_text'], [data-custom-class='body_text'] * {
        color: #595959 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        }
        [data-custom-class='link'], [data-custom-class='link'] * {
        color: #3030F1 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        word-break: break-word !important;
        }
      </style>
      <div data-custom-class="body">
      <div>
        <div align="center" class="MsoNormal" data-custom-class="title" style="text-align: left; line-height: 1.5;">
            <a name="_4r5vko5di6yg"></a>
            <strong>
              <span style="line-height: 150%; font-size: 26px;">
                  <h1>DISCLAIMER</h1>
              </span>
            </strong>
        </div>
        <div align="center" class="MsoNormal" style="text-align:center;line-height:150%;"><a name="_l2jmcqu2bv4x"></a></div>
        <div align="center" class="MsoNormal" data-custom-class="subtitle" style="text-align: left; line-height: 150%;">
            <span style="color: rgb(127,127,127); font-size: 15px; text-align: justify;">
              <strong>Last updated </strong>
              <bdt class="block-container question question-in-editor" data-id="f06b270d-4b70-bc53-bef4-2d8996dff70b" data-type="question"><strong>November 07, 2025</strong></bdt>
            </span>
        </div>
        <div class="MsoNormal" style="text-align: justify; line-height: 1.5;"><br></div>
        <div class="MsoNormal" style="text-align: justify; line-height: 1.5;"><br></div>
        <div class="MsoNormal" data-custom-class="heading_1">
            <a name="_xs0r05tcjblb"></a>
            <strong>
              <span style="line-height: 115%; font-size: 19px;">
                  <h2>WEBSITE DISCLAIMER</h2>
              </span>
            </strong>
        </div>
      </div>
      <div>
        <div class="MsoNormal" data-custom-class="body_text" style="line-height: 1.5;">
            <span style="color: rgb(89, 89, 89); font-size: 15px;">
              The information provided by
              <bdt class="block-container question question-in-editor" data-id="1e91c6ac-db3b-ab40-09dc-333e7d471e6c" data-type="question">Qwelian Tanner</bdt>
              (
              <bdt class="block-component"></bdt>
              "we," "us," or "our"
              <bdt class="statement-end-if-in-editor"></bdt>
              ) on
              <bdt class="block-component"></bdt>
              <span style="color: rgb(0, 58, 250);">
                  <bdt class="question"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com">https://www.safehemo.com</a></bdt>
              </span>
              (the
              <bdt class="block-component"></bdt>
              "Site"
              <bdt class="statement-end-if-in-editor"></bdt>
              )
              <bdt class="block-component"></bdt>
                </bdt>is for general informational purposes only. All information on
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <bdt class="block-component"></bdt>
                  the Site
                  <bdt class="block-component"></bdt>
                  </bdt>
              </span>
              is provided in good faith, however we make no representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information on
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <bdt class="block-component"></bdt>
                    the Site
                    <bdt class="block-component"></bdt>
                    </bdt>
                  </span>
              </span>
              . UNDER NO CIRCUMSTANCE SHALL WE HAVE ANY LIABILITY TO YOU FOR ANY LOSS OR DAMAGE OF ANY KIND INCURRED AS A RESULT OF THE USE OF
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <bdt class="block-component"></bdt>
                    THE SITE
                    <bdt class="block-component"></bdt>
                    </bdt>
                  </span>

              </span>
              OR RELIANCE ON ANY INFORMATION PROVIDED ON
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <span style="color: rgb(89, 89, 89); font-size: 15px;">
                        <bdt class="block-component"></bdt>
                        THE SITE
                        <bdt class="block-component"></bdt>
                        </bdt>
                    </span>
                  </span>
              </span>
              . YOUR USE OF
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <span style="color: rgb(89, 89, 89); font-size: 15px;">
                        <bdt class="block-component"></bdt>
                        THE SITE
                        <bdt class="block-component"></bdt>
                        </bdt>
                    </span>
                  </span>

              </span>
              AND YOUR RELIANCE ON ANY INFORMATION ON
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="color: rgb(89, 89, 89); font-size: 15px;">
                    <span style="color: rgb(89, 89, 89); font-size: 15px;">
                        <bdt class="block-component"></bdt>
                        THE SITE
                        <bdt class="block-component"></bdt>
                        </bdt>
                    </span>
                  </span>
              </span>
              IS SOLELY AT YOUR OWN RISK.
            </span>
        </div>
      </div>
      <div style="line-height: 1.2;"><br></div>
      <div>
        <div class="MsoNormal"><a name="_x1u8x12nt00e"></a></div>
        <bdt class="block-container if" data-type="if" id="25d6783f-eaa7-3465-7bd8-31e107cc0931">
            <bdt data-type="conditional-block">
              <bdt class="block-component" data-record-question-key="external_disclaimer_option" data-type="statement"></bdt>
            </bdt>
            <div class="MsoNormal"><a name="_wfmrqujylbbj"></a></div>
            <bdt class="block-container if" data-type="if" id="098cd9ba-027e-0afb-ec22-41e16cb68d79">
              <bdt data-type="conditional-block">
                  <bdt class="block-component" data-record-question-key="professional_disclaimer_option" data-type="statement"></bdt>
                  <bdt data-type="body">
                    <div class="MsoNormal" data-custom-class="heading_1">
                        <strong>
                          <span style="line-height: 115%; font-size: 19px;">
                              <h2>PROFESSIONAL DISCLAIMER</h2>
                          </span>
                        </strong>
                    </div>
                  </bdt>
              </bdt>
            </bdt>
      </div>
      <div><bdt class="block-container if" data-type="if"><bdt data-type="conditional-block"><bdt data-type="body"><div class="MsoNormal" data-custom-class="body_text" style="line-height: 1.5;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><bdt class="block-component"></bdt>The Site cannot and does not contain <bdt class="block-container question question-in-editor" data-id="7744aaea-18c2-bcb8-7b80-f395643dfc29" data-type="question">medical/health</bdt> advice. The <bdt class="block-container question question-in-editor" data-id="89301322-2416-ef87-b4e0-ed76500d68ee" data-type="question">medical/health</bdt> information is provided for general informational and educational purposes only and is not a substitute for professional advice. Accordingly, before taking any actions based upon such information, we encourage you to consult with the appropriate professionals. We do not provide any kind of <bdt class="block-container question question-in-editor" data-id="019392d9-ec21-89ec-6801-8fc62f11838c" data-type="question">medical/health</bdt> advice.<bdt class="statement-end-if-in-editor"></bdt> THE USE OR RELIANCE OF ANY INFORMATION CONTAINED ON <span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span style="color: rgb(89, 89, 89); font-size: 15px;"><bdt class="block-component"></bdt>THE SITE<bdt class="block-component"></bdt></bdt></span></span></span> IS SOLELY AT YOUR OWN RISK.</span></div></bdt></bdt></bdt></div>
      <div style="line-height: 1.2;"><br></div>
      <div>
        <bdt class="block-container if" data-type="if">
            <bdt class="statement-end-if-in-editor" data-type="close"></bdt>
        </bdt>
      </div>
      <div>
        <bdt class="block-component"></bdt>
        </bdt>
        <bdt data-type="conditional-block" style="text-align: start;">
            <bdt data-type="body">
              <div class="MsoNormal">
                  <bdt class="block-component"></bdt>
            </bdt>
            </span>
        </bdt>
        </bdt></bdt></bdt></bdt></span></bdt></bdt></bdt></div>
        <style>
            ul {
            list-style-type: square;
            }
            ul > li > ul {
            list-style-type: circle;
            }
            ul > li > ul > li > ul {
            list-style-type: square;
            }
            ol li {
            font-family: Arial ;
            }
        </style>
      </div>
    """
  end

  defp cookie_policy_html do
    """
      <style>
        [data-custom-class='body'], [data-custom-class='body'] * {
        background: transparent !important;
        }
        [data-custom-class='title'], [data-custom-class='title'] * {
        font-family: Arial !important;
        font-size: 26px !important;
        color: #000000 !important;
        }
        [data-custom-class='subtitle'], [data-custom-class='subtitle'] * {
        font-family: Arial !important;
        color: #595959 !important;
        font-size: 14px !important;
        }
        [data-custom-class='heading_1'], [data-custom-class='heading_1'] * {
        font-family: Arial !important;
        font-size: 19px !important;
        color: #000000 !important;
        }
        [data-custom-class='heading_2'], [data-custom-class='heading_2'] * {
        font-family: Arial !important;
        font-size: 17px !important;
        color: #000000 !important;
        }
        [data-custom-class='body_text'], [data-custom-class='body_text'] * {
        color: #595959 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        }
        [data-custom-class='link'], [data-custom-class='link'] * {
        color: #3030F1 !important;
        font-size: 14px !important;
        font-family: Arial !important;
        word-break: break-word !important;
        }
      </style>
      <span style="display: block;margin: 0 auto 3.125rem;width: 11.125rem;height: 2.375rem;background: url(data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNzgiIGhlaWdodD0iMzgiIHZpZXdCb3g9IjAgMCAxNzggMzgiPgogICAgPGcgZmlsbD0ibm9uZSIgZmlsbC1ydWxlPSJldmVub2RkIj4KICAgICAgICA8cGF0aCBmaWxsPSIjRDFEMUQxIiBkPSJNNC4yODMgMjQuMTA3Yy0uNzA1IDAtMS4yNTgtLjI1Ni0xLjY2LS43NjhoLS4wODVjLjA1Ny41MDIuMDg2Ljc5Mi4wODYuODd2Mi40MzRILjk4NXYtOC42NDhoMS4zMzJsLjIzMS43NzloLjA3NmMuMzgzLS41OTQuOTUtLjg5MiAxLjcwMi0uODkyLjcxIDAgMS4yNjQuMjc0IDEuNjY1LjgyMi40MDEuNTQ4LjYwMiAxLjMwOS42MDIgMi4yODMgMCAuNjQtLjA5NCAxLjE5OC0uMjgyIDEuNjctLjE4OC40NzMtLjQ1Ni44MzMtLjgwMyAxLjA4LS4zNDcuMjQ3LS43NTYuMzctMS4yMjUuMzd6TTMuOCAxOS4xOTNjLS40MDUgMC0uNy4xMjQtLjg4Ni4zNzMtLjE4Ny4yNDktLjI4My42Ni0uMjkgMS4yMzN2LjE3N2MwIC42NDUuMDk1IDEuMTA3LjI4NyAxLjM4Ni4xOTIuMjguNDk1LjQxOS45MS40MTkuNzM0IDAgMS4xMDEtLjYwNSAxLjEwMS0xLjgxNiAwLS41OS0uMDktMS4wMzQtLjI3LTEuMzI5LS4xODItLjI5NS0uNDY1LS40NDMtLjg1Mi0uNDQzem01LjU3IDEuNzk0YzAgLjU5NC4wOTggMS4wNDQuMjkzIDEuMzQ4LjE5Ni4zMDQuNTEzLjQ1Ny45NTQuNDU3LjQzNyAwIC43NS0uMTUyLjk0Mi0uNDU0LjE5Mi0uMzAzLjI4OC0uNzUzLjI4OC0xLjM1MSAwLS41OTUtLjA5Ny0xLjA0LS4yOS0xLjMzOC0uMTk0LS4yOTctLjUxLS40NDUtLjk1LS40NDUtLjQzOCAwLS43NTMuMTQ3LS45NDYuNDQzLS4xOTQuMjk1LS4yOS43NDItLjI5IDEuMzR6bTQuMTUzIDBjMCAuOTc3LS4yNTggMS43NDItLjc3NCAyLjI5My0uNTE1LjU1Mi0xLjIzMy44MjctMi4xNTQuODI3LS41NzYgMC0xLjA4NS0uMTI2LTEuNTI1LS4zNzhhMi41MiAyLjUyIDAgMCAxLTEuMDE1LTEuMDg4Yy0uMjM3LS40NzMtLjM1NS0xLjAyNC0uMzU1LTEuNjU0IDAtLjk4MS4yNTYtMS43NDQuNzY4LTIuMjg4LjUxMi0uNTQ1IDEuMjMyLS44MTcgMi4xNi0uODE3LjU3NiAwIDEuMDg1LjEyNiAxLjUyNS4zNzYuNDQuMjUxLjc3OS42MSAxLjAxNSAxLjA4LjIzNi40NjkuMzU1IDEuMDE5LjM1NSAxLjY0OXpNMTkuNzEgMjRsLS40NjItMi4xLS42MjMtMi42NTNoLS4wMzdMMTcuNDkzIDI0SDE1LjczbC0xLjcwOC02LjAwNWgxLjYzM2wuNjkzIDIuNjU5Yy4xMS40NzYuMjI0IDEuMTMzLjMzOCAxLjk3MWguMDMyYy4wMTUtLjI3Mi4wNzctLjcwNC4xODgtMS4yOTRsLjA4Ni0uNDU3Ljc0Mi0yLjg3OWgxLjgwNGwuNzA0IDIuODc5Yy4wMTQuMDc5LjAzNy4xOTUuMDY3LjM1YTIwLjk5OCAyMC45OTggMCAwIDEgLjE2NyAxLjAwMmMuMDIzLjE2NS4wMzYuMjk5LjA0LjM5OWguMDMyYy4wMzItLjI1OC4wOS0uNjExLjE3Mi0xLjA2LjA4Mi0uNDUuMTQxLS43NTQuMTc3LS45MTFsLjcyLTIuNjU5aDEuNjA2TDIxLjQ5NCAyNGgtMS43ODN6bTcuMDg2LTQuOTUyYy0uMzQ4IDAtLjYyLjExLS44MTcuMzMtLjE5Ny4yMi0uMzEuNTMzLS4zMzguOTM3aDIuMjk5Yy0uMDA4LS40MDQtLjExMy0uNzE3LS4zMTctLjkzNy0uMjA0LS4yMi0uNDgtLjMzLS44MjctLjMzem0uMjMgNS4wNmMtLjk2NiAwLTEuNzIyLS4yNjctMi4yNjYtLjgtLjU0NC0uNTM0LS44MTYtMS4yOS0uODE2LTIuMjY3IDAtMS4wMDcuMjUxLTEuNzg1Ljc1NC0yLjMzNC41MDMtLjU1IDEuMTk5LS44MjUgMi4wODctLjgyNS44NDggMCAxLjUxLjI0MiAxLjk4Mi43MjUuNDcyLjQ4NC43MDkgMS4xNTIuNzA5IDIuMDA0di43OTVoLTMuODczYy4wMTguNDY1LjE1Ni44MjkuNDE0IDEuMDkuMjU4LjI2MS42Mi4zOTIgMS4wODUuMzkyLjM2MSAwIC43MDMtLjAzNyAxLjAyNi0uMTEzYTUuMTMzIDUuMTMzIDAgMCAwIDEuMDEtLjM2djEuMjY4Yy0uMjg3LjE0My0uNTkzLjI1LS45Mi4zMmE1Ljc5IDUuNzkgMCAwIDEtMS4xOTEuMTA0em03LjI1My02LjIyNmMuMjIyIDAgLjQwNi4wMTYuNTUzLjA0OWwtLjEyNCAxLjUzNmExLjg3NyAxLjg3NyAwIDAgMC0uNDgzLS4wNTRjLS41MjMgMC0uOTMuMTM0LTEuMjIyLjQwMy0uMjkyLjI2OC0uNDM4LjY0NC0uNDM4IDEuMTI4VjI0aC0xLjYzOHYtNi4wMDVoMS4yNGwuMjQyIDEuMDFoLjA4Yy4xODctLjMzNy40MzktLjYwOC43NTYtLjgxNGExLjg2IDEuODYgMCAwIDEgMS4wMzQtLjMwOXptNC4wMjkgMS4xNjZjLS4zNDcgMC0uNjIuMTEtLjgxNy4zMy0uMTk3LjIyLS4zMS41MzMtLjMzOC45MzdoMi4yOTljLS4wMDctLjQwNC0uMTEzLS43MTctLjMxNy0uOTM3LS4yMDQtLjIyLS40OC0uMzMtLjgyNy0uMzN6bS4yMyA1LjA2Yy0uOTY2IDAtMS43MjItLjI2Ny0yLjI2Ni0uOC0uNTQ0LS41MzQtLjgxNi0xLjI5LS44MTYtMi4yNjcgMC0xLjAwNy4yNTEtMS43ODUuNzU0LTIuMzM0LjUwNC0uNTUgMS4yLS44MjUgMi4wODctLjgyNS44NDkgMCAxLjUxLjI0MiAxLjk4Mi43MjUuNDczLjQ4NC43MDkgMS4xNTIuNzA5IDIuMDA0di43OTVoLTMuODczYy4wMTguNDY1LjE1Ni44MjkuNDE0IDEuMDkuMjU4LjI2MS42Mi4zOTIgMS4wODUuMzkyLjM2MiAwIC43MDQtLjAzNyAxLjAyNi0uMTEzYTUuMTMzIDUuMTMzIDAgMCAwIDEuMDEtLjM2djEuMjY4Yy0uMjg3LjE0My0uNTkzLjI1LS45MTkuMzJhNS43OSA1Ljc5IDAgMCAxLTEuMTkyLjEwNHptNS44MDMgMGMtLjcwNiAwLTEuMjYtLjI3NS0xLjY2My0uODIyLS40MDMtLjU0OC0uNjA0LTEuMzA3LS42MDQtMi4yNzggMC0uOTg0LjIwNS0xLjc1Mi42MTUtMi4zMDEuNDEtLjU1Ljk3NS0uODI1IDEuNjk1LS44MjUuNzU1IDAgMS4zMzIuMjk0IDEuNzI5Ljg4MWguMDU0YTYuNjk3IDYuNjk3IDAgMCAxLS4xMjQtMS4xOTh2LTEuOTIyaDEuNjQ0VjI0SDQ2LjQzbC0uMzE3LS43NzloLS4wN2MtLjM3Mi41OTEtLjk0Ljg4Ni0xLjcwMi44ODZ6bS41NzQtMS4zMDZjLjQyIDAgLjcyNi0uMTIxLjkyMS0uMzY1LjE5Ni0uMjQzLjMwMi0uNjU3LjMyLTEuMjR2LS4xNzhjMC0uNjQ0LS4xLTEuMTA2LS4yOTgtMS4zODYtLjE5OS0uMjc5LS41MjItLjQxOS0uOTctLjQxOWEuOTYyLjk2MiAwIDAgMC0uODUuNDY1Yy0uMjAzLjMxLS4zMDQuNzYtLjMwNCAxLjM1IDAgLjU5Mi4xMDIgMS4wMzUuMzA2IDEuMzMuMjA0LjI5Ni40OTYuNDQzLjg3NS40NDN6bTEwLjkyMi00LjkyYy43MDkgMCAxLjI2NC4yNzcgMS42NjUuODMuNC41NTMuNjAxIDEuMzEyLjYwMSAyLjI3NSAwIC45OTItLjIwNiAxLjc2LS42MiAyLjMwNC0uNDE0LjU0NC0uOTc3LjgxNi0xLjY5LjgxNi0uNzA1IDAtMS4yNTgtLjI1Ni0xLjY1OS0uNzY4aC0uMTEzbC0uMjc0LjY2MWgtMS4yNTF2LTguMzU3aDEuNjM4djEuOTQ0YzAgLjI0Ny0uMDIxLjY0My0uMDY0IDEuMTg3aC4wNjRjLjM4My0uNTk0Ljk1LS44OTIgMS43MDMtLjg5MnptLS41MjcgMS4zMWMtLjQwNCAwLS43LjEyNS0uODg2LjM3NC0uMTg2LjI0OS0uMjgzLjY2LS4yOSAxLjIzM3YuMTc3YzAgLjY0NS4wOTYgMS4xMDcuMjg3IDEuMzg2LjE5Mi4yOC40OTUuNDE5LjkxLjQxOS4zMzcgMCAuNjA1LS4xNTUuODA0LS40NjUuMTk5LS4zMS4yOTgtLjc2LjI5OC0xLjM1IDAtLjU5MS0uMS0xLjAzNS0uMy0xLjMzYS45NDMuOTQzIDAgMCAwLS44MjMtLjQ0M3ptMy4xODYtMS4xOTdoMS43OTRsMS4xMzQgMy4zNzljLjA5Ni4yOTMuMTYzLjY0LjE5OCAxLjA0MmguMDMzYy4wMzktLjM3LjExNi0uNzE3LjIzLTEuMDQybDEuMTEyLTMuMzc5aDEuNzU3bC0yLjU0IDYuNzczYy0uMjM0LjYyNy0uNTY2IDEuMDk2LS45OTcgMS40MDctLjQzMi4zMTItLjkzNi40NjgtMS41MTIuNDY4LS4yODMgMC0uNTYtLjAzLS44MzMtLjA5MnYtMS4zYTIuOCAyLjggMCAwIDAgLjY0NS4wN2MuMjkgMCAuNTQzLS4wODguNzYtLjI2Ni4yMTctLjE3Ny4zODYtLjQ0NC41MDgtLjgwM2wuMDk2LS4yOTUtMi4zODUtNS45NjJ6Ii8+CiAgICAgICAgPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNzMpIj4KICAgICAgICAgICAgPGNpcmNsZSBjeD0iMTkiIGN5PSIxOSIgcj0iMTkiIGZpbGw9IiNFMEUwRTAiLz4KICAgICAgICAgICAgPHBhdGggZmlsbD0iI0ZGRiIgZD0iTTIyLjQ3NCAxNS40NDNoNS4xNjJMMTIuNDM2IDMwLjRWMTAuMzYzaDE1LjJsLTUuMTYyIDUuMDh6Ii8+CiAgICAgICAgPC9nPgogICAgICAgIDxwYXRoIGZpbGw9IiNEMkQyRDIiIGQ9Ik0xMjEuNTQ0IDE0LjU2di0xLjcyOGg4LjI3MnYxLjcyOGgtMy4wMjRWMjRoLTIuMjR2LTkuNDRoLTMuMDA4em0xMy43NDQgOS41NjhjLTEuMjkgMC0yLjM0MS0uNDE5LTMuMTUyLTEuMjU2LS44MS0uODM3LTEuMjE2LTEuOTQ0LTEuMjE2LTMuMzJzLjQwOC0yLjQ3NyAxLjIyNC0zLjMwNGMuODE2LS44MjcgMS44NzItMS4yNCAzLjE2OC0xLjI0czIuMzYuNDAzIDMuMTkyIDEuMjA4Yy44MzIuODA1IDEuMjQ4IDEuODggMS4yNDggMy4yMjQgMCAuMzEtLjAyMS41OTctLjA2NC44NjRoLTYuNDY0Yy4wNTMuNTc2LjI2NyAxLjA0LjY0IDEuMzkyLjM3My4zNTIuODQ4LjUyOCAxLjQyNC41MjguNzc5IDAgMS4zNTUtLjMyIDEuNzI4LS45NmgyLjQzMmEzLjg5MSAzLjg5MSAwIDAgMS0xLjQ4OCAyLjA2NGMtLjczNi41MzMtMS42MjcuOC0yLjY3Mi44em0xLjQ4LTYuNjg4Yy0uNC0uMzUyLS44ODMtLjUyOC0xLjQ0OC0uNTI4cy0xLjAzNy4xNzYtMS40MTYuNTI4Yy0uMzc5LjM1Mi0uNjA1LjgyMS0uNjggMS40MDhoNC4xOTJjLS4wMzItLjU4Ny0uMjQ4LTEuMDU2LS42NDgtMS40MDh6bTcuMDE2LTIuMzA0djEuNTY4Yy41OTctMS4xMyAxLjQ2MS0xLjY5NiAyLjU5Mi0xLjY5NnYyLjMwNGgtLjU2Yy0uNjcyIDAtMS4xNzkuMTY4LTEuNTIuNTA0LS4zNDEuMzM2LS41MTIuOTE1LS41MTIgMS43MzZWMjRoLTIuMjU2di04Ljg2NGgyLjI1NnptNi40NDggMHYxLjMyOGMuNTY1LS45NyAxLjQ4My0xLjQ1NiAyLjc1Mi0xLjQ1Ni42NzIgMCAxLjI3Mi4xNTUgMS44LjQ2NC41MjguMzEuOTM2Ljc1MiAxLjIyNCAxLjMyOC4zMS0uNTU1LjczMy0uOTkyIDEuMjcyLTEuMzEyYTMuNDg4IDMuNDg4IDAgMCAxIDEuODE2LS40OGMxLjA1NiAwIDEuOTA3LjMzIDIuNTUyLjk5Mi42NDUuNjYxLjk2OCAxLjU5Ljk2OCAyLjc4NFYyNGgtMi4yNHYtNC44OTZjMC0uNjkzLS4xNzYtMS4yMjQtLjUyOC0xLjU5Mi0uMzUyLS4zNjgtLjgzMi0uNTUyLTEuNDQtLjU1MnMtMS4wOS4xODQtMS40NDguNTUyYy0uMzU3LjM2OC0uNTM2Ljg5OS0uNTM2IDEuNTkyVjI0aC0yLjI0di00Ljg5NmMwLS42OTMtLjE3Ni0xLjIyNC0uNTI4LTEuNTkyLS4zNTItLjM2OC0uODMyLS41NTItMS40NC0uNTUycy0xLjA5LjE4NC0xLjQ0OC41NTJjLS4zNTcuMzY4LS41MzYuODk5LS41MzYgMS41OTJWMjRoLTIuMjU2di04Ljg2NGgyLjI1NnpNMTY0LjkzNiAyNFYxMi4xNmgyLjI1NlYyNGgtMi4yNTZ6bTcuMDQtLjE2bC0zLjQ3Mi04LjcwNGgyLjUyOGwyLjI1NiA2LjMwNCAyLjM4NC02LjMwNGgyLjM1MmwtNS41MzYgMTMuMDU2aC0yLjM1MmwxLjg0LTQuMzUyeiIvPgogICAgPC9nPgo8L3N2Zz4K) center no-repeat;"></span>
      <div data-custom-class="body">
        <div>
            <strong>
              <span style="font-size: 26px;">
                  <span data-custom-class="title">
                    <h1>COOKIE POLICY</h1>
                  </span>
              </span>
            </strong>
        </div>
        <div>
            <span style="color: rgb(127, 127, 127);">
              <strong>
                  <span style="font-size: 15px;">
                    <span data-custom-class="subtitle">
                        Last updated
                        <bdt class="question">November 07, 2025</bdt>
                    </span>
                  </span>
              </strong>
            </span>
        </div>
        <div><br></div>
        <div><br></div>
        <div><br></div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span data-custom-class="body_text">
                    This Cookie Policy explains how
                    <bdt class="question">__________</bdt>
                    ("<strong>Company</strong>," "<strong>we</strong>," "<strong>us</strong>," and "<strong>our</strong>") uses cookies and similar technologies to recognize you when you visit our website at
                  </span>
              </span>
              <span style="color: rgb(0, 58, 250); font-size: 15px;">
                  <span data-custom-class="body_text">
                    <bdt class="question"><a target="_blank" data-custom-class="link" href="https://www.safehemo.com">https://www.safehemo.com</a></bdt>
                  </span>
              </span>
              <span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text"> ("<strong>Website</strong>"). It explains what these technologies are and why we use them, as well as your rights to control our use of them.</span></span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text">In some cases we may use cookies to collect personal information, or that becomes personal information if we combine it with other information.</span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(0, 0, 0); font-size: 15px;">
                  <strong>
                    <span data-custom-class="heading_1">
                        <h2>What are cookies?</h2>
                    </span>
                  </strong>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><span style="color: rgb(127, 127, 127);"><span style="color: rgb(89, 89, 89); font-size: 15px;"><span data-custom-class="body_text">Cookies are small data files that are placed on your computer or mobile device when you visit a website. Cookies are widely used by website owners in order to make their websites work, or to work more efficiently, as well as to provide reporting information.</span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span data-custom-class="body_text">
                    Cookies set by the website owner (in this case,
                    <bdt class="question">__________</bdt>
                    ) are called "first-party cookies." Cookies set by parties other than the website owner are called "third-party cookies." Third-party cookies enable third-party features or functionality to be provided on or through the website (e.g., advertising, interactive content, and analytics). The parties that set these third-party cookies can recognize your computer both when it visits the website in question and also when it visits certain other websites.
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(0, 0, 0); font-size: 15px;">
                  <strong>
                    <span data-custom-class="heading_1">
                        <h2>Why do we use cookies?</h2>
                    </span>
                  </strong>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span data-custom-class="body_text">
                    We use first-
                    <bdt class="block-component"></bdt>
                    and third-
                    <bdt class="statement-end-if-in-editor"></bdt>
                    party cookies for several reasons. Some cookies are required for technical reasons in order for our Website to operate, and we refer to these as "essential" or "strictly necessary" cookies. Other cookies also enable us to track and target the interests of our users to enhance the experience on our Online Properties.
                    <bdt class="block-component"></bdt>
                    Third parties serve cookies through our Website for advertising, analytics, and other purposes.
                    <bdt class="statement-end-if-in-editor"></bdt>
                    This is described in more detail below.
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span id="control" style="color: rgb(0, 0, 0);">
                          <strong>
                              <span data-custom-class="heading_1">
                                <h2>How can I control cookies?</h2>
                              </span>
                          </strong>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">You have the right to decide whether to accept or reject cookies. You can exercise your cookie rights by setting your preferences in the Cookie Consent Manager. The Cookie Consent Manager allows you to select which categories of cookies you accept or reject. Essential cookies cannot be rejected as they are strictly necessary to provide you with services.</span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">The Cookie Consent Manager can be found in the notification banner and on our Website. If you choose to reject cookies, you may still use our Website though your access to some functionality and areas of our Website may be restricted. You may also set or amend your web browser controls to accept or refuse cookies.</span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">The specific types of first- and third-party cookies served through our Website and the purposes they perform are described in the table below (please note that the specific </span><span data-custom-class="body_text">cookies served may vary depending on the specific Online Properties you visit):</span></span></span><span style="font-size: 15px;"></span></div>
        <div><br></div>
        <div>
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(0, 0, 0); font-size: 15px;">
                  <strong>
                    <span data-custom-class="heading_1">
                        <h2>How can I control cookies on my browser?</h2>
                    </span>
                  </strong>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><span data-custom-class="body_text">As the means by which you can refuse cookies through your web browser controls vary from browser to browser, you should visit your browser's help menu for more information. The following is information about how to manage cookies on the most popular browsers:</span><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.google.com/chrome/answer/95647#zippy=%2Callow-or-block-cookies" rel="noopener noreferrer" target="_blank"></a></span></div>
        <ul>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.google.com/chrome/answer/95647#zippy=%2Callow-or-block-cookies" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Chrome</span></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.microsoft.com/en-us/windows/delete-and-manage-cookies-168dab11-0753-043d-7c16-ede5947fc64d" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Internet Explorer</span></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.mozilla.org/en-US/kb/enhanced-tracking-protection-firefox-desktop?redirectslug=enable-and-disable-cookies-website-preferences&redirectlocale=en-US" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Firefox</span></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.apple.com/en-ie/guide/safari/sfri11471/mac" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Safari</span></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://support.microsoft.com/en-us/windows/microsoft-edge-browsing-data-and-privacy-bb8174ba-9d73-dcf2-9b4a-c582b4e640dd" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Edge</span></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://help.opera.com/en/latest/web-preferences/" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Opera</span></a></span></li>
        </ul>
        <div style="line-height: 1.5;"><span data-custom-class="body_text">In addition, most advertising networks offer you a way to opt out of targeted advertising. If you would like to find out more information, please visit:</span><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.aboutads.info/choices/" rel="noopener noreferrer" target="_blank"></a></span></div>
        <ul>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.aboutads.info/choices/" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Digital Advertising Alliance</span></a></span><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://youradchoices.ca/" rel="noopener noreferrer" target="_blank"></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="https://youradchoices.ca/" rel="noopener noreferrer" target="_blank"><span style="color: rgb(0, 58, 250); font-size: 15px;">Digital Advertising Alliance of Canada</span></a></span><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.youronlinechoices.com/" rel="noopener noreferrer" target="_blank"></a></span></li>
            <li style="line-height: 1.5;"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.youronlinechoices.com/" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">European Interactive Digital Advertising Alliance</span></a></span></li>
        </ul>
        <div><br></div>
        <div>
            <strong>
              <span data-custom-class="heading_1">
                  <h2>What about other tracking technologies, like web beacons?</h2>
              </span>
            </strong>
        </div>
        <div style="line-height: 1.5;">
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        Cookies are not the only way to recognize or track visitors to a website. We may use other, similar technologies from time to time, like web beacons (sometimes called "tracking pixels" or "clear gifs"). These are tiny graphics files that contain a unique identifier that enables us to recognize when someone has visited our Website
                        <bdt class="block-component"></bdt>
                        or opened an email including them
                        <bdt class="statement-end-if-in-editor"></bdt>
                        . This allows us, for example, to monitor
                    </span>
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="color: rgb(89, 89, 89);">
                          <span data-custom-class="body_text">the traffic patterns of users from one page within a website to another, to deliver or communicate with cookies, to understand whether you have come to the website from an online advertisement displayed on a third-party website, to improve site performance, and to measure the success of email marketing campaigns. In many instances, these technologies are reliant on cookies to function properly, and so declining cookies will impair their functioning.</span>
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span data-custom-class="heading_1">
              <strong>
                  <h2>Do you use Flash cookies or Local Shared Objects?</h2>
              </strong>
            </span>
        </div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Websites may also use so-called "Flash Cookies" (also known as Local Shared Objects or "LSOs") to, among other things, collect and store information about your use of our services, fraud prevention, and for other site operations.</span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">If you do not want Flash Cookies stored on your computer, you can adjust the settings of your Flash player to block Flash Cookies storage using the tools contained in the </span></span><span data-custom-class="body_text"><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager07.html" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Website Storage Settings Panel</span></a></span><span style="font-size: 15px; color: rgb(89, 89, 89);">. You can also control Flash Cookies by going to the </span><span style="color: rgb(0, 58, 250);"><a data-custom-class="link" href="http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html" rel="noopener noreferrer" target="_blank"><span style="font-size: 15px;">Global Storage Settings Panel</span></a></span></span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text"> and </span><span style="font-size:15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">following the instructions (which may include instructions that explain, for example, how to delete existing Flash Cookies (referred to "information" on the Macromedia site), how to prevent Flash LSOs from being placed on your computer without your being asked, and (for Flash Player 8 and later) how to block Flash Cookies that are not being delivered by the operator of the page you are on at the time).</span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Please note that setting the Flash Player to restrict or limit acceptance of Flash Cookies may reduce or impede the functionality of some Flash applications, including, potentially, Flash applications used in connection with our services or online content.</span></span></span>
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="color: rgb(89, 89, 89);">
                          <bdt class="statement-end-if-in-editor"></bdt>
                          <bdt class="block-component"></bdt>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <strong>
              <span data-custom-class="heading_1">
                  <h2>Do you serve targeted advertising?</h2>
              </span>
            </strong>
        </div>
        <div style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">Third parties may serve cookies on your computer or mobile device to serve advertising through our Website. These companies may use information about your visits to this and other websites in order to provide relevant advertisements about goods and services that you may be interested in. They may also employ technology that is used to measure the effectiveness of advertisements. They can accomplish this by using cookies or web beacons to collect information about your visits to this and other sites in order to provide relevant advertisements about goods and services of potential interest to you. The information collected through this process does not enable us or them to identify your name, contact details, or other details that directly identify you unless you choose to provide these.</span></span>
            <span style="color: rgb(127, 127, 127);">
              <span style="color: rgb(89, 89, 89); font-size: 15px;">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span style="font-size: 15px; color: rgb(89, 89, 89);">
                        <span style="color: rgb(89, 89, 89);">
                          <bdt class="statement-end-if-in-editor"></bdt>
                        </span>
                    </span>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <strong>
              <span data-custom-class="heading_1">
                  <h2>How often will you update this Cookie Policy?</h2>
              </span>
            </strong>
        </div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">We may update </span><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">this Cookie Policy from time to time in order to reflect, for example, changes to the cookies we use or for other operational, legal, or regulatory reasons. Please therefore revisit this Cookie Policy regularly to stay informed about our use of cookies and related technologies.</span></span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span style="font-size: 15px; color: rgb(89, 89, 89);"><span data-custom-class="body_text">The date at the top of this Cookie Policy indicates when it was last updated.</span></span></span></span></div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <strong>
              <span data-custom-class="heading_1">
                  <h2>Where can I get further information?</h2>
              </span>
            </strong>
        </div>
        <div style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span style="font-size: 15px; color: rgb(89, 89, 89);">
                    <span data-custom-class="body_text">
                        If you have any questions about our use of cookies or other technologies, please
                        <bdt class="block-component"></bdt>
                        contact us at
                        <bdt class="statement-end-if-in-editor"></bdt>
                        :
                    </span>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;"><br></div>
        <div style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <span data-custom-class="body_text">
                    <bdt class="question">__________</bdt>
                  </span>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;">
            <bdt class="block-component"><span style="font-size: 15px;"></span></bdt>
        </div>
        <div style="line-height: 1.5;">
            <span style="font-size: 15px; color: rgb(89, 89, 89);">
              <span data-custom-class="body_text">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </div>
        <div style="line-height: 1.5;">
            <bdt class="block-component"></bdt>
            <span data-custom-class="body_text">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <bdt class="block-component"></bdt>
                  <bdt class="block-component"></bdt>
                  <bdt class="block-component">
                    <bdt class="block-component"></bdt>
                  </bdt>
              </span>
            </span>
            <span data-custom-class="body_text">
              <span style="font-size: 15px; color: rgb(89, 89, 89);">
                  <bdt class="block-component"></bdt>
              </span>
            </span>
        </div>
      </div>
      <style>
        ul {
        list-style-type: square;
        }
        ul > li > ul {
        list-style-type: circle;
        }
        ul > li > ul > li > ul {
        list-style-type: square;
        }
        ol li {
        font-family: Arial ;
        }
      </style>
      </div>
    """
  end
end
