# frozen_string_literal: true

class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    de: { writing: :primary_de, reading: :primary_de_replica }
  }

  def self.with_shard
    shard = Current.account&.shard_key&.to_sym || try(:account)&.shard_key&.to_sym || :de
    connected_to(shard: shard, role: :writing) { yield }
  end
end
