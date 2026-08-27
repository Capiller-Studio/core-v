# frozen_string_literal: true

module EmailTemplates
  class Creator < ApplicationService
    attr_reader :account, :name, :template_type, :layout

    def initialize(account:, name:, template_type:, layout: nil)
      @account = account
      @name = name
      @template_type = template_type
      @layout = layout
    end

    def call
      account.with_shard do
        ShardRecord.transaction do
          # Load the default MJML body for this template type
          mjml_body = default_mjml_for(template_type)

          locale = account.locale.presence || I18n.default_locale.to_s
          subject = default_subject_for(template_type, locale)

          template = EmailTemplate.new(
            account: account,
            name: name,
            template_type: template_type,
            status: :inactive, # Starts inactive
            email_template_layout: layout
          )

          template.save!

          # Create a starter draft translation for the account's primary locale only
          template.translations.create!(
            locale: locale,
            draft_subject: subject,
            draft_body: mjml_body
          )

          template
        end
      end
    end

    private

    def default_mjml_for(type)
      seed_data_path = File.expand_path("../seeds/email_template_data", __dir__)
      file_path = File.join(seed_data_path, "templates", "#{type}.mjml")
      File.exist?(file_path) ? File.read(file_path) : "<mjml><mj-body><mj-section><mj-column><mj-text>New Template</mj-text></mj-column></mj-section></mj-body></mjml>"
    end

    def default_subject_for(type, locale)
      I18n.t(
        "seeds.email_templates.#{type}.subject",
        locale: locale,
        default: type.to_s.titleize
      )
    end
  end
end
