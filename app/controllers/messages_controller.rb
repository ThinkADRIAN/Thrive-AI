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

    if ai_message.present?
      sms = send_message(from_number, ai_message)
    end

    handle_action(from_number, ai_response)
    handle_contexts(from_number, ai_response)
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

  def reset_contexts
    @ai_client.text_request resetContexts: true
  end

  def send_follow_up_message(recipient_number, message, context_input, reset_context_flag)
    ai_response = get_ai_response(message, context_input, reset_context_flag)
    ai_message = ai_response[:result][:speech]
    send_message(recipient_number, ai_message)
  end

  def handle_contexts(from_number, ai_response)
    ai_contexts = get_contexts(ai_response)

    case
      when ai_contexts.include?('greeting-delivered')
        send_follow_up_message(from_number, 'declare_bot_purpose', [], true)
        send_follow_up_message(from_number, 'request_decision_to_send_how_it_works', [], true)
        #send_follow_up_message(from_number, 'request_user_joy_rating', [], false)
      when ai_contexts.include?('bot-purpose-delivered')
        send_follow_up_message(from_number, 'request_decision_to_send_how_it_works', [], true)
      when ai_contexts.include?('decision-to-send-how-it-works-received')
        decision = ai_response[:result][:parameters][:yes_or_no]
        if decision == 'yes'
          send_message_script(from_number, 'how it works')
        else
          send_follow_up_message(from_number, 'respond_to_how_it_works_denial', ['how-it-works-denied'], true)
        end
        send_follow_up_message(from_number, 'request_decision_to_start_demo', [], true)
      when ai_contexts.include?('decision-to-start-demo-received')
        decision = ai_response[:result][:parameters][:yes_or_no]
        if decision == 'yes'
          send_message_script(from_number, 'the thrive community')
          # TODO: insert request for response
          send_message_script(from_number, 'defining support')
          send_follow_up_message(from_number, 'request_decision_to_start_practice', [], true)
        else
          send_follow_up_message(from_number, 'respond_to_start_demo_denial', ['start-demo-denied'], true)
          # TODO: insert request for response
        end
      when ai_contexts.include?('user-joy-rating-received')
        respond_to_user_joy_rating(from_number, ai_response)
      when ai_contexts.include?('user-instruction-received')
      else
        # TODO: insert request for response
    end
  end

  def handle_action(from_number, ai_response)
    ai_action = ai_response[:result][:action]

    case ai_action
      when 'create_joy_rating'
        user_joy_rating = ai_response[:result][:parameters][:joy_rating]
        @current_thriver.ratings.create(joy: user_joy_rating)
      when 'submit_instruction'
        user_instruction = ai_response[:result][:parameters][:user_instructions]

        case user_instruction
          when 'help_self'

          when 'help_other'

          else

        end
      when 'tell_user_how_it_works'
        send_message_script(from_number, 'how it works')
        reset_contexts
      when 'send_directions'
        send_message_script(from_number, 'a little help for our friends')
        reset_contexts
      else

    end
  end

  def respond_to_user_joy_rating(from_number, ai_response)
    user_joy_rating = ai_response[:result][:parameters][:joy_rating].to_i

    case
      when user_joy_rating.between?(8,10)
        # Suggest give help
        send_follow_up_message(from_number, 'respond_to_user_joy_rating_8_10', [], true)
      when user_joy_rating.between?(4,7)
        # Suggest both
        send_follow_up_message(from_number, 'respond_to_user_joy_rating_4_7', [], true)
      when user_joy_rating.between?(1,3)
        # Suggest get help
        send_follow_up_message(from_number, 'respond_to_user_joy_rating_1_3', [], true)
      else

    end
  end

  def send_message_script(recipient_number, script_title)
    messages = get_message_script(script_title)

    messages.each do |message|
      send_message(recipient_number, message)
    end
  end

  def get_message_script(script_title)
    case script_title
      when 'how it works'
        [
            'I can connect you to our network of Thrivers from all over the world.',
            'It is completely anonymous, so you can share openly without fear',
            'You can get help from the community and give help to people facing challenges',
            'Helping others is a great way to pay it forward!'
        ]
      when 'the thrive community'
        [
            'Let me start with the power of our community',
            'Thrive is a positive and supportive community!',
            'No one is perfect and we don’t expect anyone to be.',
            'This is a place to help your self and others.',
        ]
      when 'defining support'
        [
            'The type of support we give can be different than most people are used to…',
            'We focus on providing HOPE rather than solutions.',
            'When you’re not feeling at your best, it can suck to be told what to do.',
            'Some people try to help by saying, “JUST DO THIS”',
            'That’s why we help people to find the ‘Silver Lining’ aka HOPE!'
        ]
      when 'a little help for our friends'
        [
            'Looks like you could use a little assistance',
            'Here are some suggested things I know how to respond to...',
            'Hi! | What is your purpose? | How does this work? '
        ]
      else
    end
  end
end