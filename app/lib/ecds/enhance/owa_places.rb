# frozen_string_literal: true

require 'elasticsearch'
require 'httparty'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class OwaPlaces < Ecds::Enhance::Owa
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 26, collection: 'owa_places')
        @document = document
      end

      def enhance
        @document[:has_wp] = @document[:wordpress_id].present?
        @document[:link] = link if @document[:wordpress_id].present?
        @document
      end

      def link
        response = HTTParty.get("https://owarebrand.ecdsdev.org/wp-json/wp/v2/posts/#{@document[:wordpress_id]}", format: 'plain')
        puts response.code
        return unless response.code == 200

        data = JSON.parse(response.body).deep_symbolize_keys!
        puts data[:link]
        data[:link]
      end
    end
  end
end
