# frozen_string_literal: true

module Ecds
  # The invitation CoreDataConnector::InvitationMailer sends as a Postmark
  # template, written out as a plain-text email so it can go through SES.
  class InvitationMailer < ActionMailer::Base
    default from: 'noreply@ecds.io'

    def invite_user(user:, password:, project:)
      @user = user
      @password = password
      @project = project
      @url = ENV.fetch('HOSTNAME', 'https://coredata.ecds.io')

      mail(to: user.email, subject: "You've been invited to FairData")
    end
  end
end
