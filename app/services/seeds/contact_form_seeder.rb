# frozen_string_literal: true

module Seeds
  class ContactFormSeeder
    def self.seed(account)
      puts "Seeding ContactForm channel for account: #{account.id}..."

      channel = Channel::ContactForm.find_or_create_by!(
        name: "General Contact Form",
        account: account
      ) do |c|
        c.configurations = {
          "primary_color" => "#10B981",
          "welcome_message" => "Please fill out the form below and our team will get back to you shortly.",
          "success_message_i18n_key" => "contact_form.success"
        }
        c.require_login = false
        c.allow_attachments = true
        c.send_confirmation_email = true
      end

      inbox = channel.inboxes.find_or_create_by!(
        name: "Contact Form Inbox",
        account: account
      ) do |i|
        i.primary_inbox = true
      end
      inbox.update!(primary_inbox: true) unless inbox.primary_inbox?

      # Ensure default custom fields exist
      Accounts::DefaultCustomFieldsCreator.call(account: account)

      # Associate all custom fields with this contact form
      account.custom_fields.each_with_index do |custom_field, index|
        channel.custom_field_resources.find_or_create_by!(
          custom_field: custom_field
        ) do |cfr|
          cfr.position = index + 1
          cfr.configurations = {}
        end
      end

      puts "✅ ContactForm channel seeded successfully."
    end
  end
end
