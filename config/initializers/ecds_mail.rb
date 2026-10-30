# frozen_string_literal: true

require_relative '../../lib/ecds/ses_delivery_method'

# Production sends mail through Amazon SES in place of the Postmark delivery
# set in config/application.rb.
if Rails.env.production?
  ActionMailer::Base.add_delivery_method(:ses, Ecds::SesDeliveryMethod, region: ENV.fetch('AWS_REGION', 'us-east-1'))
  ActionMailer::Base.delivery_method = :ses

  # The invitation is a Postmark template, which SES can't render, so
  # Ecds::InvitationMailer sends it instead.
  Rails.application.config.to_prepare do
    CoreDataConnector::InvitationMailer.define_singleton_method(:invite_user) do |**args|
      Ecds::InvitationMailer.invite_user(**args)
    end
  end
end
