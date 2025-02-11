# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastTopics < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 13, collection: 'georgia_coast_topics')
        @document = document
      end

      def enhance
        @document[:videos] = enhance_videos(@document[:videos])
        @document
      end
    end
  end
end
