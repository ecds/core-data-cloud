#!/bin/bash
./typesense-server --config=./typesense-server.ini &

# set -e

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

bundle install
bundle exec ./bin/rake db:prepare
bundle exec rake core_data_connector:iiif:reset_manifests &
chmod +x create_index.sh
./create_index.sh &
bundle exec whenever --update-crontab
bundle exec puma -C config/puma.rb