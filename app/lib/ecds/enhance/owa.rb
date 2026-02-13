# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class Owa < Ecds::BaseEnhancer
      def initialize(document)
        super
        @factory = RGeo::Geographic.spherical_factory
      end
    end
  end
end
