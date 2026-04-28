Searchkick.client = Elasticsearch::Client.new(
  url: ENV.fetch("ELASTICSEARCH_URL") { "http://localhost:9200" },
  user: ENV.fetch("ELASTICSEARCH_USER", "elastic"),
  password: ENV.fetch("ELASTICSEARCH_PASSWORD", "SaNBS-XD+dP*EyOvVcKc")
)