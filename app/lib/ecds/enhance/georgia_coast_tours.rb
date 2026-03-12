# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastTours < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 58, collection: 'georgia_coast_tours')
        @document = document
      end

      def enhance
        @document[:description] = otb_description if @document[:type] == "OpenTour"
        @document[:thumbnail_url] = otb_thumbnail_url if @document[:type] == "OpenTour"
        @document[:publisher] = publisher unless @document[:publisher].nil?
        @document
      end

      private

      def otb_description
        response = HTTParty.get(@document[:link])
        doc = Nokogiri::HTML.parse(response.body)
        element = doc.xpath("/html/head/meta[@property='og:description']").first
        return if element.nil?

        element[:content]
      end

      def otb_thumbnail_url
        response = HTTParty.get(@document[:link])
        doc = Nokogiri::HTML.parse(response.body)
        element = doc.xpath("/html/head/meta[@property='og:image:secure_url']").first
        return if element.nil?

        element[:content]
      end

      def publisher
        return "<cite>#{@document[:publisher]}</cite>, #{@document[:volume]}, no. #{@document[:issue]}" if @document[:volume]

        "#{@document[:city]}: #{@document[:publisher]}"
      end
    end
  end
end
