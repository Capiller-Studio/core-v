# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_web_widget_translations
#
#  id                :uuid             not null, primary key
#  launcher_text     :string
#  locale            :string           not null
#  pre_chat_subtitle :string
#  pre_chat_title    :string
#  reply_time_text   :string
#  welcome_tagline   :string
#  welcome_title     :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  web_widget_id     :uuid             not null
#
# Indexes
#
#  index_cwwt_on_widget_and_locale  (web_widget_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (web_widget_id => channel_web_widgets.id)
#
module Channel
  class WebWidgetTranslation < ShardRecord
    belongs_to :web_widget, class_name: "Channel::WebWidget"

    validates :locale, presence: true, uniqueness: { scope: :web_widget_id }
  end
end
