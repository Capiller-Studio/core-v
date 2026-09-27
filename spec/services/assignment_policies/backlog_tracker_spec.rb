# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentPolicies::BacklogTracker do
  let(:account_id) { 42 }
  let(:key) { "BACKLOG_STATUS:42" }

  before do
    RedisUtilities::Helpers.delete(key)
  end

  after do
    RedisUtilities::Helpers.delete(key)
  end

  describe ".backlog_pending?" do
    it "returns true on cold start / uninitialized nil state" do
      expect(described_class.backlog_pending?(account_id)).to be true
    end

    it "returns true when backlog is marked as 1" do
      described_class.mark_backlog_exists(account_id)
      expect(described_class.backlog_pending?(account_id)).to be true
    end

    it "returns false when backlog is cleared to 0" do
      described_class.mark_backlog_cleared(account_id)
      expect(described_class.backlog_pending?(account_id)).to be false
    end

    it "returns true if redis raises an error" do
      allow(RedisUtilities::Helpers).to receive(:get).and_raise(Redis::CannotConnectError)
      expect(described_class.backlog_pending?(account_id)).to be true
    end
  end

  describe ".mark_backlog_exists" do
    it "sets key to 1" do
      described_class.mark_backlog_exists(account_id)
      expect(RedisUtilities::Helpers.get(key)).to eq("1")
    end
  end

  describe ".mark_backlog_cleared" do
    it "sets key to 0" do
      described_class.mark_backlog_cleared(account_id)
      expect(RedisUtilities::Helpers.get(key)).to eq("0")
    end
  end
end
