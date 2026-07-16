# frozen_string_literal: true

# Seeds default email templates and layout for a new account.
# Creates a default layout + all system templates with translations
# in every available locale. Both published and draft fields are
# initialized identically so users can start editing immediately.
module Seeds
  class EmailTemplateSeeder
    SEED_DATA_PATH = File.expand_path("email_template_data", __dir__).freeze

    def self.seed(account)
      new(account).seed
    end

    def initialize(account)
      @account = account
    end

    def seed
      layout = seed_layout
      seed_templates(layout)
    end

    private

    attr_reader :account

    def seed_layout
      layout = account.email_template_layouts.find_or_create_by!(name: "Default Layout")

      mjml = File.read(File.join(SEED_DATA_PATH, "layouts", "default_layout.mjml"))

      [account.locale.to_sym].each do |locale|
        next if layout.translated_to?(locale)

        layout.translations.create!(
          locale: locale.to_s,
          body: mjml,
          draft_body: mjml,
          design: {},
          draft_design: {}
        )
      end

      layout
    end

    def seed_templates(layout)
      EmailTemplate::SYSTEM_TEMPLATES.each do |template_name|
        template = account.email_templates.find_or_initialize_by(name: template_name)
        template.template_type = template_name
        template.email_template_layout = layout
        template.status = :inactive
        template.save!

        mjml_path = File.join(SEED_DATA_PATH, "templates", "#{template_name}.mjml")
        mjml = File.exist?(mjml_path) ? File.read(mjml_path) : ""

        [account.locale.to_sym].each do |locale|
          next if template.translated_to?(locale)

          subject = I18n.t(
            "seeds.email_templates.#{template_name}.subject",
            locale: locale,
            default: template_name.titleize
          )

          template.translations.create!(
            locale: locale.to_s,
            subject: subject,
            body: mjml,
            draft_body: mjml,
            design: {},
            draft_design: {}
          )
        end
      end
    end
  end
end
