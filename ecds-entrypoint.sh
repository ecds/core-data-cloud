#!/bin/bash
set -e

if [ -f /app/tmp/pids/server.pid ]; then
	rm /app/tmp/pids/server.pid
fi

# A task started with a command (the deploy's migration task, or a Sidekiq
# service) runs just that command. Migrations are not run here: the deploy
# runs them in their own task before any service restarts.
if [ "$#" -gt 0 ]; then
	exec "$@"
fi

exec bundle exec puma -C config/puma.rb
