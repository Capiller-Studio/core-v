# frozen_string_literal: true

# Seeds default email templates for an account
# Called when creating a new account to provide default editable templates
module Seeds
  class EmailTemplateSeeder
    def self.seed(account)
      EmailTemplate::SYSTEM_TEMPLATES.each do |template_name|
        template = account.email_templates.find_or_create_by!(name: template_name)

        # Create default English translation from i18n seeds
        unless template.translated_to?(:en)
          template.translations.create!(
            locale: "en",
            subject: I18n.t("seeds.email_templates.#{template_name}.subject", locale: :en),
            body: I18n.t("seeds.email_templates.#{template_name}.body", locale: :en)
          )
        end
      end
    end
  end
end
