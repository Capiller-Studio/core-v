# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_portals
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  default_locale    :string           default("en"), not null
#  flags             :integer          default(0), not null
#  locales           :string           default(["en"]), not null, is an Array
#  name              :string
#  status            :integer          default("active"), not null
#  ui_configurations :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  domain_id         :uuid             not null
#
# Indexes
#
#  index_help_center_portals_on_account_id                     (account_id)
#  index_help_center_portals_on_account_id_and_created_at      (account_id,created_at)
#  index_help_center_portals_on_account_id_and_default_locale  (account_id,default_locale)
#  index_help_center_portals_on_account_id_and_name            (account_id,name)
#  index_help_center_portals_on_account_id_and_status          (account_id,status)
#  index_help_center_portals_on_domain_id                      (domain_id) UNIQUE
#
module HelpCenter
  class Portal < ShardRecord
    include FlagShihTzu

    belongs_to :account
    belongs_to :domain

    has_many :categories, dependent: :destroy
    has_many :articles,   dependent: :destroy
    has_many :translations, class_name: "HelpCenter::PortalTranslation", dependent: :destroy
    has_many :redirects,    class_name: "HelpCenter::Redirect",          dependent: :destroy

    # Web widget is already linked via Channel::WebWidget#portal_id (FK on that table)
    has_one :web_widget_channel,   class_name: "Channel::WebWidget", dependent: :nullify
    # Contact form channel — links this portal to its embeddable support/contact form
    has_one :contact_form_channel, class_name: "Channel::ContactForm", dependent: :nullify

    has_one_attached :logo              # Brand logo shown in portal header
    has_one_attached :favicon           # Browser tab icon (ICO/PNG, 32x32 or 64x64)
    has_one_attached :social_share_image # OG image for social media previews (1200x630px)
    has_one_attached :hero_image        # Background image for hero section (used when hero_style == "image")

    enum :status, { active: 0 }

    # Feature flags (stored in :flags integer column via FlagShihTzu bit flags):
    #   show_contact_form   — enable /contact page for ticket submission
    #   show_customer_portal — enable /my-tickets page for end-user conversation history (requires customer login)
    #   show_web_widget     — embed the linked web widget on this portal
    #   indexing_enabled    — allow search engines to crawl/index this portal
    has_flags 1 => :show_contact_form,
              2 => :show_customer_portal,
              3 => :show_web_widget,
              4 => :indexing_enabled,
              column: "flags"

    # ui_configurations jsonb — visual/theme settings only (no feature flags here):
    # {
    #   "theme_mode"       => "light | dark | system",
    #   "primary_color"    => "#7E61F0",
    #   "secondary_color"  => "#3A3060",
    #   "font_family"      => "Inter",
    #   "hero_style"       => "gradient | image | plain",
    #   "category_layout"  => "grid | list"
    # }

    # configurations jsonb — non-visual, non-flag settings:
    # {
    #   "google_analytics_id" => "UA-XXXXX",
    #   "custom_css"          => ""           (injected into <style> tag on portal pages)
    # }
  end
end
