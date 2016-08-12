class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def reply
    message_body = params['Body']
    from_number = params['From']

    if Thriver.exists?(phone_number: from_number)
      @current_thriver = Thriver.find_by(phone_number: from_number)
    else
      @current_thriver = Thriver.new(phone_number: from_number, password: from_number)
      @current_thriver.save
    end

    boot_twilio
    boot_api_ai

    ai_response = get_ai_response(message_body, [], false)
    ai_message = ai_response[:result][:speech]

    sms = send_message(from_number, ai_message)

    handle_contexts(from_number, ai_response)
    handle_action(ai_response)
  end

  private

  def boot_twilio
    account_sid = ENV['TWILIO_SID']
    auth_token = ENV['TWILIO_TOKEN']
    @client = Twilio::REST::Client.new account_sid, auth_token
  end

  def send_message(recipient_number, message)
    @client.messages.create(
        from: ENV['TWILIO_NUMBER'],
        to: recipient_number,
        body: message
    )
  end

  def boot_api_ai
    @ai_client = ApiAiRuby::Client.new(
                                      client_access_token: ENV['API_AI_CLIENT_ACCESS_TOKEN']
    )
  end

  def get_ai_response(message, context_input, reset_context_flag)
    if context_input.nil?
      context_input = []
    end

    if reset_context_flag.nil?
      reset_context_flag = false
    end

    @ai_client.text_request message, contexts: context_input, resetContexts: reset_context_flag
  end

  def get_contexts(ai_response)
    ai_contexts = []

    ai_response[:result][:contexts].each do |context|
      ai_contexts.push(context[:name])
    end

    ai_contexts
  end

  def send_follow_up_message(recipient_number, message, context_input, reset_context_flag)
    ai_response = get_ai_response(message, context_input, reset_context_flag)
    ai_message = ai_response[:result][:speech]
    send_message(recipient_number, ai_message)
  end

  def handle_contexts(from_number, ai_response)
    ai_contexts = get_contexts(ai_response)

    case
      when ai_contexts.include?('greeting-responded-to')
        send_follow_up_message(from_number, 'declare_bot_purpose', [], true)
        send_follow_up_message(from_number, 'request_user_joy_rating', [], false)
      when ai_contexts.include?('user-joy-rating-received')
        send_follow_up_message(from_number, 'request_user_instruction', [], true)
      when ai_contexts.include?('user-instruction-received')
      else

    end
  end

  def handle_action(ai_response)
    ai_action = ai_response[:result][:action]

    case ai_action
      when 'create_joy_rating'
        user_joy_rating = ai_response[:result][:parameters][:joy_rating]
        @current_thriver.ratings.create(joy: user_joy_rating)
      when 'submit_instruction'
        user_instruction = ai_response[:result][:parameters[:user_instructions]]

        case user_instruction
          when 'help_self'

          when 'help_other'

          else

        end
      else

    end
  end
end