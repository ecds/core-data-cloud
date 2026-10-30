#!/bin/bash
set -e

if [ -f /app/tmp/pids/server.pid ]; then
	rm /app/tmp/pids/server.pid
fi

bundle install

# A task started with a command (the deploy's migration task, or a Sidekiq
# service) runs just that command. Migrations are not run here: the deploy
# runs them in their own task before any service restarts.
if [ "$#" -gt 0 ]; then
	exec "$@"
fi

bundle exec rake core_data_connector:iiif:reset_manifests &
# bundle exec rake ecds_index:update -- --collection="georgia_coast" --project_model_id=6 &
exec bundle exec puma -C config/puma.rb
