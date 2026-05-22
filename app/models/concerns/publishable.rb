# frozen_string_literal: true

# Provides a safe draft/publish workflow for translatable records.
#
# Editor UI reads/writes draft fields (draft_body, draft_design).
# Publishing copies draft → live fields and triggers compilation.
# Mailers and public-facing code only read published fields (body, compiled_html).
#
# Requirements for including models:
#   - Translation table must have: body, design, compiled_html, draft_body, draft_design
#   - Model must include Translateable with these fields in TRANSLATABLE_FIELDS
#   - Model should implement #compile_body(mjml_source) returning HTML string
#
# Reusable for: EmailTemplate, EmailTemplateLayout, HelpCenter::Article (future)
module Publishable
  extend ActiveSupport::Concern

  # Publish the current draft for a specific locale.
  # Copies draft fields → published fields, compiles MJML → HTML.
  def publish!(locale: I18n.locale)
    with_locale_and_fresh_cache(locale) do
      raise I18n.t("errors.publishable.no_draft_content") if draft_body.blank?

      self.body = draft_body
      self.design = draft_design

      # Compile MJML → HTML if the model supports it
      self.compiled_html = compile_body(body) if respond_to?(:compile_body, true)

      save!
    end

    # If this is a layout, recompile child templates
    recompile_child_templates(locale:) if respond_to?(:recompile_child_templates, true)
  end

  # Discard unpublished draft changes, reset to published version.
  def discard_draft!(locale: I18n.locale)
    with_locale_and_fresh_cache(locale) do
      target = translations.find { |t| t.locale.to_s == locale.to_s }
      return unless target

      self.draft_body = target.body
      self.draft_design = nil if respond_to?(:draft_design=)
      target.draft_subject = nil if target.respond_to?(:draft_subject=)
      
      save!
    end
  end

  # Check if draft content differs from published content.
  def has_unpublished_changes?(locale: I18n.locale)
    with_locale_and_fresh_cache(locale) do
      target = translations.find { |t| t.locale.to_s == locale.to_s }
      return false unless target

      body_changed = target.draft_body.present? && target.draft_body != target.body
      subject_changed = target.respond_to?(:draft_subject) && target.draft_subject.present? && target.draft_subject != target.subject
      
      body_changed || subject_changed
    end
  end

  # Save only draft fields (called by editor "Save Draft" action).
  def save_draft!(draft_body_content:, draft_design_content:, draft_subject_content: nil, locale: I18n.locale)
    with_locale_and_fresh_cache(locale) do
      target = translations.find { |t| t.locale.to_s == locale.to_s } || translations.build(locale: locale.to_s)
      target.draft_body = draft_body_content
      target.draft_design = draft_design_content if target.respond_to?(:draft_design=)
      target.draft_subject = draft_subject_content if target.respond_to?(:draft_subject=) && draft_subject_content.present?

      self.draft_body = draft_body_content
      self.draft_design = draft_design_content if respond_to?(:draft_design=)
      
      save!
    end
  end

  # Initialize draft from published content (for first-time edit).
  def initialize_draft!(locale: I18n.locale)
    with_locale_and_fresh_cache(locale) do
      target = translations.find { |t| t.locale.to_s == locale.to_s } || translations.build(locale: locale.to_s)
      
      # We must check the specific target translation because calling self.draft_body 
      # falls back to the default locale and falsely appears present!
      return if target.draft_body.present?

      if target.new_record?
        if target.respond_to?(:subject=) && target.subject.blank?
          target.subject = subject.presence || "New Subject"
        end
        if target.respond_to?(:body=) && target.body.blank?
          target.body = body.presence || "<mjml><mj-body></mj-body></mjml>"
        end
      end

      self.draft_body = target.body
      self.draft_design = design || {}
      target.draft_subject = target.subject if target.respond_to?(:draft_subject=)
      
      save!
    end
  end

  # Copy draft content from one locale to another.
  # Enables users to clone a design between locales instead of recreating from scratch.
  def copy_draft_locale!(from:, to:)
    source = translations.find_by(locale: from.to_s)
    raise I18n.t("errors.publishable.source_locale_missing", locale: from.to_s.upcase) unless source

    target = translations.find_or_initialize_by(locale: to.to_s)
    target.draft_body = source.draft_body.presence || source.body
    target.draft_design = source.draft_design.presence || source.design
    
    if target.respond_to?(:draft_subject=)
      target.draft_subject = source.draft_subject.presence || source.subject
    end
    target.subject = source.subject if target.respond_to?(:subject=) && target.subject.blank?
    target.save!

    # Clear cache so the editor picks up the new content
    @_translations_cache = nil
  end

  private

  # Wraps operations in a locale context with a fresh translation cache.
  # The Translateable concern caches translations per attribute without
  # locale awareness, so we must reset it when switching locales.
  def with_locale_and_fresh_cache(locale)
    I18n.with_locale(locale) do
      # Reset Translateable's internal cache to avoid cross-locale data leaks
      @_translations_cache = nil
      yield
    ensure
      @_translations_cache = nil
    end
  end
end
