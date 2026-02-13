# frozen_string_literal: true

# Open the rails console and run
# load './georgia_coast_topic_tree.rb'

require 'elasticsearch'
require 'core_data_connector/taxonomy'

client = Elasticsearch::Client.new(
  host: ENV['ELASTICSEARCH_HOST'],
  api_key: ENV['ELASTICSEARCH_API_KEY'],
  retry_on_failure: true,
  transport_options: {
    request: { timeout: 20 }
  }
)

collection = 'georgia_coast_topic_tree'

topics = CoreDataConnector::Taxonomy.where(project_model_id: 13)
relations = CoreDataConnector::Relationship.where(project_model_relationship_id: 39)
parents = topics.reject { |r| relations.map(&:related_record).include? r }
tree = parents.map do |p|
  {
    slug: p.name.parameterize,
    label: p.name,
    sub_topics: relations.where(primary_record: p).map do |sub|
      subs = relations.where(primary_record: sub.related_record)
      if subs.empty?
        {
          slug: sub.related_record.name.parameterize,
          label: sub.related_record.name,
          parent_topics: [p.name.parameterize]
        }
      else
        {
          slug: sub.related_record.name.parameterize,
          label: sub.related_record.name,
          parent_topics: [p.name.parameterize],
          sub_topics: subs.map do |r|
            subs = relations.where(primary_record: r.related_record)
            if subs.empty?
              {
                slug: r.related_record.name.parameterize,
                label: r.related_record.name,
                parent_topics: [p.name.parameterize, sub.related_record.name.parameterize]
              }
            else
              {
                slug: r.related_record.name.parameterize,
                label: r.related_record.name,
                parent_topics: [p.name.parameterize, sub.related_record.name.parameterize],
                sub_topics: subs.map do |s|
                  {
                    slug: s.related_record.name.parameterize,
                    label: s.related_record.name,
                    parent_topics: [p.name.parameterize, sub.related_record.name.parameterize, r.related_record.name.parameterize]
                  }
                end
              }
            end
          end
        }
      end
    end
  }
end

requests = [{ index: { _index: collection, _id: 'JcV1tZYBScXy9kOSVsBL', data: { doc: tree } } }]

client.bulk(body: requests)
