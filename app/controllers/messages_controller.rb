class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    boot_api_ai
    response = @ai_client.text_request message_body
    ai_response = response[:result][:speech]

    boot_twilio
    sms = @client.messages.create(
                              from: ENV["twilio_number"],
                              to: from_number,
                              body: ai_response
    )
  end

  private

  def boot_twilio
    account_sid = ENV["twilio_sid"]
    auth_token = ENV["twilio_token"]
    @client = Twilio::REST::Client.new account_sid, auth_token
  end

  def boot_api_ai
    @ai_client = ApiAiRuby::Client.new(
                                      client_access_token: ENV["api_ai_client_access_token"]
    )
  end

  @ai_client = ApiAiRuby::Client.new(
      client_access_token: '5f423ed0ba4f4ef3a427a56185889232'
  )
end