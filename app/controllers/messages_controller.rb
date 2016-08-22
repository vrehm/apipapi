class MessagesController < ApplicationController

 #vérifier le skip_before_filter (skipp la vérification de l'auth token)
 skip_before_filter :verify_authenticity_token

 #skip l'auth token pour Devise
 skip_before_filter :authenticate_user!, :only => "reply"

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    boot_twilio
    sms = @client.messages.create(
      from: ENV['TWILIO_NUMBER'],
      to: '+33665579224',
      body: "Hello there, thanks for texting me. Your number is #{from_number}."
    )

  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
  end
end
