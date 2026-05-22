# frozen_string_literal: true

# == Schema Information
#
# Table name: email_template_layouts
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             not null
#
class EmailTemplateLayout < ShardRecord
  include Translateable
  include Publishable

  TRANSLATABLE_FIELDS = %i[body design compiled_html draft_body draft_design].freeze

  CONTENT_PLACEHOLDER = "[[CONTENT_FOR_LAYOUT]]"

  belongs_to :account
  has_many :email_templates, dependent: :nullify
  has_many :attachments, as: :resource, dependent: :destroy

  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true

  private

  # Called by Publishable#publish! to compile MJML → HTML.
  def compile_body(mjml_source)
    Emails::TemplateCompilerService.compile(mjml_source)
  end

  # Called by Publishable#publish! after layout is published.
  # Recompile all child templates that reference this layout.
  def recompile_child_templates(locale: I18n.locale)
    email_templates.find_each do |template|
      I18n.with_locale(locale) do
        template.instance_variable_set(:@_translations_cache, nil)
        next unless template.body.present?

        template.compiled_html = template.send(:compile_body, template.body)
        template.save!
      end
    end
  end
end
