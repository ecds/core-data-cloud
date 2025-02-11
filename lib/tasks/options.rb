# frozen_string_literal: true

module Ecds
  class Options
    def self.parse(args, &block)
      options = {}

      opts = OptionParser.new

      block.call(opts, options) if block.present?

      opts.on('-c', '--collection ARG', String) { |collection_name| options[:collection] = collection_name }
      opts.on('-r', '--record_id ARG', String) { |record_id| options[:record_id] = record_id }
      args = opts.order!(args) {}
      opts.parse!(args)

      options
    end
  end
end
