class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def reply
    message_body = params["Body"]
    @from_number = params["From"]

    boot_twilio
    boot_api_ai

    @ai_response = @ai_client.text_request message_body
    @ai_message = @ai_response[:result][:speech]

    sms = send_message(@from_number, @ai_message)

    #handle_action
  end

  private

  def boot_twilio
    account_sid = ENV["twilio_sid"]
    auth_token = ENV["twilio_token"]
    @client = Twilio::REST::Client.new account_sid, auth_token
  end

  def send_message(recipient_number, message)
    @client.messages.create(
        from: ENV["twilio_number"],
        to: recipient_number,
        body: message
    )
  end

  def boot_api_ai
    @ai_client = ApiAiRuby::Client.new(
                                      client_access_token: ENV["api_ai_client_access_token"]
    )
  end

  def handle_action
    @ai_action = @ai_response[:result][:action]
    send_message(@from_number, @ai_action)
  end
end