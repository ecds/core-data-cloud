# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastWorks < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 17, collection: 'georgia_coast_works')
        @document = document
      end

      def enhance
        @document[:year] = Date.strptime(@document[:year_str]).year if @document[:year_str]
        @document[:citation] = citation
        @document
      end

      private

      def citation
        parts = [
          @document[:author],
          "<cite>#{@document[:title]}</cite>",
          @document[:pages],
          publisher,
          @document[:year],
          link
        ]

        "#{parts.compact.join('. ')}."
      end

      def link
        return nil unless @document[:link]

        "<a href='#{@document[:link]}'>#{@document[:link]}</a>"
      end

      def publisher
        return "<cite>#{@document[:publisher]}</cite>, #{@document[:volume]}, no. #{@document[:issue]}" if @document[:volume]

        "#{@document[:city]}: #{@document[:publisher]}"
      end
    end
  end
end
