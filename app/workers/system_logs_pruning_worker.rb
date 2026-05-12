# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class SystemLogsPruningWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform
    # High-performance chunked raw database deletions avoiding memory inflation
    SystemLog.expired.in_batches(of: 5000).delete_all
  rescue StandardError => e
    Rails.logger.error("SystemLogsPruningWorker failed: #{e.message}")
  end
end
