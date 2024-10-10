# frozen_string_literal: true

module Elasticsearch
  class Options
    def self.parse(args, &block)
      options = {}

      opts = OptionParser.new

      block.call(opts, options) if block.present?

      opts.on('-c', '--collection ARG', String) { |collection_name| options[:collection] = collection_name }
      opts.on('-m', '--project_model_id ARG', Integer) { |project_model| options[:project_model_id] = project_model }
      args = opts.order!(args) {}
      opts.parse!(args)

      options
    end
  end
end
