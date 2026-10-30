# frozen_string_literal: true

module Ecds
  # ActionMailer delivery method that sends through Amazon SES. Credentials come
  # from the AWS SDK's standard chain: on ECS, the task role.
  class SesDeliveryMethod
    def initialize(settings)
      @settings = settings || {}
    end

    def deliver!(mail)
      client.send_raw_email(raw_message: { data: mail.to_s })
    end

    private

    def client
      @client ||= Aws::SES::Client.new(region: @settings.fetch(:region))
    end
  end
end
