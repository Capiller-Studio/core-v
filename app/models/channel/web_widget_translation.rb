# frozen_string_literal: true
# == Schema Information
#
# Table name: channel_web_widget_translations
#
#  id                :uuid             not null, primary key
#  web_widget_id     :uuid             not null
#  locale            :string           not null
#  launcher_text     :string
#  reply_time_text   :string
#  pre_chat_title    :string
#  pre_chat_subtitle :string
#  welcome_title     :string
#  welcome_tagline   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_cwwt_on_widget_and_locale  (web_widget_id,locale) UNIQUE
#

module Channel
  class WebWidgetTranslation < ShardRecord
    belongs_to :web_widget, class_name: "Channel::WebWidget"

    validates :locale, presence: true, uniqueness: { scope: :web_widget_id }
  end
end
