#!/bin/bash
set -e

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

bundle install
bundle exec ./bin/rake db:prepare
bundle exec rake core_data_connector:iiif:reset_manifests &
bundle exec rake ecds_index:index -- --collection="georgia_coast" --project_model_id=6 &
bundle exec puma -C config/puma.rb