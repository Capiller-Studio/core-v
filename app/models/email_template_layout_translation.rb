# frozen_string_literal: true

class EmailTemplateLayoutTranslation < ShardRecord
  belongs_to :email_template_layout

  validates :locale, presence: true, uniqueness: { scope: :email_template_layout_id }
  validates :body, presence: true
end
