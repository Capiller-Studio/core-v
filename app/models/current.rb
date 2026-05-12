# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account, :ip_address, :user_agent, :request_id
end
