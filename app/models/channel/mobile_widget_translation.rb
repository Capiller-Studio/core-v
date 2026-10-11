# frozen_string_literal: true

module Channel
  class MobileWidgetTranslation < ShardRecord
    belongs_to :mobile_widget, class_name: "Channel::MobileWidget"

    validates :locale, presence: true, uniqueness: { scope: :mobile_widget_id }
  end
end
