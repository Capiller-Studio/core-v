# frozen_string_literal: true

module ShardResolvable
  extend ActiveSupport::Concern

  included do
    def with_shard
      ShardRecord.connected_to(shard: shard_key.to_sym, role: :writing) { yield }
    end
  end
end
