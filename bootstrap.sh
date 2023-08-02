#!/bin/bash
# In development environment, Elasticsearch is empty and needs to be configured. A template and an index are created.
# At this moment, it's also safe to rebuild the database for the development environment.

set -e

export DISABLE_DATABASE_ENVIRONMENT_CHECK=1

# Run migrations
printf 'Setting up database...'

bundle exec rake db:setup