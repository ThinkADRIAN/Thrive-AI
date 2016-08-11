class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def reply
    message_body = params["Body"]
    @from_number = params["From"]

    boot_twilio
    boot_api_ai

    ai_response = @ai_client.text_request message_body
    @ai_message = ai_response[:result][:speech]

    sms = send_message(@from_number, @ai_message)

    handle_contexts(ai_response)
    #handle_action(ai_response)
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

  def get_contexts(ai_response)
    ai_contexts = []

    ai_response[:result][:contexts].each do |context|
      ai_contexts.push(context[:name])
    end

    ai_contexts
  end

  def handle_contexts(ai_response)
    ai_contexts = get_contexts(ai_response)

    if ai_contexts.include?("join-init")
      ai_response = @ai_client.text_request "declare_bot_purpose", contexts: ["declare-bot-purpose"],  resestContexts: true
      ai_message = ai_response[:result][:speech]
      sms = send_message(@from_number, ai_message)
      ai_response = @ai_client.text_request "request_user_joy_rating", resestContexts: true
      ai_message = ai_response[:result][:speech]
      sms = send_message(@from_number, ai_message)
    end
  end

  def handle_action(ai_response)
    ai_action = ai_response[:result][:action]
    send_message(@from_number, ai_action)
  end
end