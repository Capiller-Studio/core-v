# frozen_string_literal: true

module UsageTrackable
  extend ActiveSupport::Concern

  class_methods do
    def tracks_usage(resource_name, enforce: true, decrement_on_destroy: true, error_message: nil, if: nil)
      condition = binding.local_variable_get(:if)
      res_sym = resource_name.to_sym

      define_singleton_method(:usage_tracked_resource) { res_sym }
      define_singleton_method(:usage_enforce_limit) { enforce }
      define_singleton_method(:usage_decrement_on_destroy) { decrement_on_destroy }
      define_singleton_method(:usage_limit_error_message) { error_message }
      define_singleton_method(:usage_trackable_condition) { condition }

      before_create(:enforce_account_usage_limit!, if: :enforce_usage_limit?)
      after_create_commit(:increment_account_usage, if: :track_usage_on_create?)
      after_destroy_commit(:decrement_account_usage, if: :decrement_usage_on_destroy?)
    end
  end

  private

  def trackable_condition_met?
    return true if self.class.usage_trackable_condition.nil?

    case self.class.usage_trackable_condition
    when Symbol, String
      send(self.class.usage_trackable_condition)
    when Proc
      instance_exec(&self.class.usage_trackable_condition)
    else
      true
    end
  end

  def skip_usage_tracking?
    (respond_to?(:system_provided?) && system_provided?) || !trackable_condition_met?
  end

  def track_usage_on_create?
    !skip_usage_tracking?
  end

  def enforce_usage_limit?
    self.class.usage_enforce_limit && !skip_usage_tracking?
  end

  def decrement_usage_on_destroy?
    self.class.usage_decrement_on_destroy && !skip_usage_tracking?
  end

  def enforce_account_usage_limit!
    return unless account
    return if account.within_limit?(self.class.usage_tracked_resource)

    res_sym = self.class.usage_tracked_resource
    human_name = I18n.t("resources.#{res_sym}", default: res_sym.to_s.humanize)
    default_msg = self.class.usage_limit_error_message || "#{human_name} limit reached for your plan. Please upgrade."
    model_key = self.class.model_name.i18n_key

    msg = I18n.t(
      :"activerecord.errors.models.#{model_key}.attributes.base.limit_reached",
      default: [
        :'activerecord.errors.messages.limit_reached',
        default_msg
      ],
      resource: human_name
    )

    errors.add(:base, msg)
    throw(:abort)
  end

  def increment_account_usage
    account&.increment_usage!(self.class.usage_tracked_resource)
  end

  def decrement_account_usage
    account&.decrement_usage!(self.class.usage_tracked_resource)
  end
end
