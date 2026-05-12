# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class ActivityPresenter
  attr_reader :activity

  def initialize(activity)
    @activity = activity
  end

  # Converts low-level attribute JSON diffs into professional human-readable change summaries via pure I18n templates
  def humanized_changes
    changes = activity.object_changes.dup
    sentences = []

    changes.each do |attr_name, diff|
      if attr_name.start_with?("translation_")
        target_lang = attr_name.sub("translation_", "").upcase
        sentences << I18n.t("activities.presenter.translation_updated", target_locale: target_lang, default: "Updated translation contents for locale %{target_locale}")
      elsif diff.is_a?(Array) && diff.size == 2
        old_val, new_val = diff
        human_attr = format_attribute_name(attr_name)

        if is_enum?(attr_name)
          old_resolved = resolve_enum(attr_name, old_val)
          new_resolved = resolve_enum(attr_name, new_val)
          sentences << I18n.t(
            "activities.presenter.enum_changed",
            attribute: human_attr,
            old: old_resolved,
            new: new_resolved,
            default: "Changed %{attribute} from '%{old}' to '%{new}'"
          )
        else
          sentences << I18n.t("activities.presenter.attribute_updated", attribute: human_attr, default: "Updated %{attribute}")
        end
      end
    end

    sentences.presence || [activity.translated_description]
  end

  private

  def format_attribute_name(attr_name)
    if activity.trackable_type.present?
      model_class = activity.trackable_type.safe_constantize
      return model_class.human_attribute_name(attr_name.to_s) if model_class&.respond_to?(:human_attribute_name)
    end
    attr_name.to_s.humanize.downcase
  end

  def is_enum?(attr_name)
    return false unless activity.trackable_type.present?
    model_class = activity.trackable_type.safe_constantize
    model_class&.respond_to?(:defined_enums) && model_class.defined_enums.key?(attr_name.to_s)
  end

  def resolve_enum(attr_name, value)
    return value.to_s if value.blank?
    model_class = activity.trackable_type.safe_constantize
    mapping = model_class.defined_enums[attr_name.to_s]
    
    # Resolve humanized mapping key from raw database storage string or integer
    found_key = mapping.key(value.to_i) || mapping.key(value.to_s) || value.to_s
    found_key.humanize
  end
end
