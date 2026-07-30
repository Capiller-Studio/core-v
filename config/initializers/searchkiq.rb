# frozen_string_literal: true

# Elasticsearch / Searchkick configuration.
#
# In development: values come from .env file (loaded by dotenv-rails).
# In production:  values come from system ENV variables set on the server.
#
# See .env.sample for the full list of expected ENV variables.
Searchkick.client = Elasticsearch::Client.new(
  url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"),
  user: ENV.fetch("ELASTICSEARCH_USER", "elastic"),
  password: ENV.fetch("ELASTICSEARCH_PASSWORD", "changeme"),
  transport_options: { ssl: { verify: false } }
)
