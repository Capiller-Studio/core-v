# frozen_string_literal: true

module Routable
  extend ActiveSupport::Concern

  included do
    after_save :register_global_routing
    after_destroy :remove_global_routing
  end

  def routing_identifier
    # Override in model if needed. Default to 'page_id' or 'email' or 'id'
    return page_identifier if respond_to?(:page_identifier)
    return email if respond_to?(:email)
    id
  end

  def routing_type
    # e.g. 'facebook_page', 'email'
    self.class.name.demodulize.underscore
  end

  def global_routing
    GlobalRouting.find_by(
      route_type: routing_type,
      route_value: routing_identifier,
      account_id: account_id
    )
  end

  def global_routing_id
    global_routing&.id
  end

  private

  def register_global_routing
    return if routing_identifier.blank?

    # We use update_all or find_or_initialize to avoid infinite loops if saved again
    # This must be done on the Primary DB
    ActiveRecord::Base.connected_to(role: :writing) do
      routing = GlobalRouting.find_or_initialize_by(
        route_type: routing_type,
        route_value: routing_identifier
      )
      routing.update!(
        account_id: account_id,
        shard_key: account.shard_key
      )
    end
  end

  def remove_global_routing
    ActiveRecord::Base.connected_to(role: :writing) do
      GlobalRouting.where(
        route_type: routing_type,
        route_value: routing_identifier,
        account_id: account_id
      ).delete_all
    end
  end
end
