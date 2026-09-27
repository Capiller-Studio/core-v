# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class SystemLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :logs, retry: 3

  def perform(params = {})
    params = params.with_indifferent_access

    account_id = params[:account_id]
    account = Account.find_by(id: account_id) if account_id.present?

    log_level = params[:level] || params[:log_level] || :info

    SystemLog.create!(
      account:    account,
      event_key:  params[:event_key],
      log_level:  log_level,
      message:    params[:message],
      payload:    params[:payload] || {},
      metadata:   params[:metadata] || {}
    )
  rescue StandardError => e
    Rails.logger.error("SystemLogWorker failed: #{e.message}")
  end
end
