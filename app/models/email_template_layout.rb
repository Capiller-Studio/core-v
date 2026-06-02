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

  publishable_fields :body, :design

  TRANSLATABLE_FIELDS = %i[body design compiled_html draft_body draft_design].freeze

  CONTENT_PLACEHOLDER = "[[CONTENT_FOR_LAYOUT]]"

  belongs_to :account
  has_many :email_templates, dependent: :nullify
  has_many :attachments, as: :resource, dependent: :destroy

  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true

  before_create :enforce_email_template_layouts_limit!
  after_create_commit :increment_email_template_layouts_usage
  after_destroy_commit :decrement_email_template_layouts_usage

  private

  def enforce_email_template_layouts_limit!
    return if account.within_limit?(:email_template_layouts)

    errors.add(:base, "Email template layouts limit reached for your plan. Please upgrade.")
    throw(:abort)
  end

  def increment_email_template_layouts_usage
    account.increment_usage!(:email_template_layouts)
  end

  def decrement_email_template_layouts_usage
    account.decrement_usage!(:email_template_layouts)
  end

  # Model-specific lifecycle callbacks for Publishable concern

  def after_publish_assignments!(locale)
    # Compile MJML → HTML before the record is saved
    self.compiled_html = Emails::TemplateCompilerService.compile(body)
  end

  def after_publish!(locale)
    # Recompile all child templates that reference this layout.
    email_templates.find_each do |template|
      I18n.with_locale(locale) do
        template.instance_variable_set(:@_translations_cache, nil)
        next unless template.body.present?

        # We need to manually recompile the child's MJML with our new layout body
        template.compiled_html = Emails::TemplateCompilerService.compile_with_layout(template.body, layout_body: body)
        template.save!
      end
    end
  end
end
