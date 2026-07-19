# frozen_string_literal: true

# Provides a draft/publish workflow for translatable records.
#
# Requirements for including models:
#   - Translation table must have the live and draft fields configured via `publishable_fields`
#   - Model must include Translateable with these fields in TRANSLATABLE_FIELDS
#
module Publishable
  extend ActiveSupport::Concern

  included do
    # Lifecycle hooks that models can override
    def before_publish_draft!(locale); end
    def after_publish_assignments!(locale); end
    def after_publish!(locale); end
    def before_discard_draft!(locale); end
    def after_discard_draft!(locale); end
    def before_save_draft!(locale); end
    def after_save_draft!(locale); end
    def before_initialize_draft!(locale); end
    def after_initialize_draft!(locale); end
    def before_copy_draft_locale!(from:, to:); end
    def after_copy_draft_locale!(from:, to:); end
  end

  class_methods do
    # Generates draft/publish methods for the specified fields without any runtime reflection.
    # E.g., `publishable_fields :subject, :body, :design`
    def publishable_fields(*fields)
      raise(ArgumentError, "Must provide at least one field to publishable_fields") if fields.empty?
      
      # For publish!
      publish_assignments = fields.map do |f|
        "self.#{f} = self.draft_#{f}"
      end.join("\n        ")
      
      # For has_unpublished_changes?
      has_changes_checks = fields.map do |f|
        "!target.draft_#{f}.nil? && target.draft_#{f} != target.#{f}"
      end.join(" ||\n            ")

      # For discard_draft!
      discard_assignments = fields.map do |f|
        "self.draft_#{f} = target.#{f}"
      end.join("\n        ")

      # For save_draft!
      # We need to map kwargs to the respective draft fields.
      save_kwargs = fields.map { |f| "draft_#{f}_content: nil" }.join(", ")
      
      save_target_assignments = fields.map do |f|
        "target.draft_#{f} = draft_#{f}_content unless draft_#{f}_content.nil?"
      end.join("\n            ")

      save_self_assignments = fields.map do |f|
        "self.draft_#{f} = draft_#{f}_content unless draft_#{f}_content.nil?"
      end.join("\n            ")

      # For initialize_draft!
      # Initialize draft fields with the fallback of live fields.
      init_new_record_fallbacks = fields.map do |f|
        "target.#{f} = public_send(:#{f}).presence if target.#{f}.blank?"
      end.join("\n          ")

      init_assignments = fields.map do |f|
        "self.draft_#{f} = target.#{f}"
      end.join("\n        ")

      # For copy_draft_locale!
      copy_assignments = fields.map do |f|
        "target.draft_#{f} = source.draft_#{f}.presence || source.#{f}"
      end.join("\n        ")

      # The first field is treated as the primary "content" field to check if a draft exists at all
      primary_draft_field = "draft_#{fields.first}"

      generated_code = <<-RUBY
        def publish!(locale: I18n.locale)
          with_locale_and_fresh_cache(locale) do
            raise I18n.t("errors.publishable.no_draft_content") if self.#{primary_draft_field}.blank?

            before_publish_draft!(locale)

            #{publish_assignments}

            after_publish_assignments!(locale)

            save!
          end
          after_publish!(locale)
        end

        def discard_draft!(locale: I18n.locale)
          with_locale_and_fresh_cache(locale) do
            target = translations.find { |t| t.locale.to_s == locale.to_s }
            return unless target

            before_discard_draft!(locale)

            #{discard_assignments}

            after_discard_draft!(locale)

            save!
          end
        end

        def has_unpublished_changes?(locale: I18n.locale)
          with_locale_and_fresh_cache(locale) do
            target = translations.find { |t| t.locale.to_s == locale.to_s }
            return false unless target

            #{has_changes_checks}
          end
        end

        def save_draft!(#{save_kwargs}, locale: I18n.locale)
          with_locale_and_fresh_cache(locale) do
            target = translations.find { |t| t.locale.to_s == locale.to_s } || translations.build(locale: locale.to_s)
            
            before_save_draft!(locale)

            #{save_target_assignments}
            #{save_self_assignments}

            after_save_draft!(locale)

            save!
          end
        end

        def initialize_draft!(locale: I18n.locale)
          with_locale_and_fresh_cache(locale) do
            target = translations.find { |t| t.locale.to_s == locale.to_s } || translations.build(locale: locale.to_s)
            
            return if target.#{primary_draft_field}.present?

            before_initialize_draft!(locale)

            if target.new_record?
              #{init_new_record_fallbacks}
            end

            #{init_assignments}

            after_initialize_draft!(locale)

            save!
          end
        end

        def copy_draft_locale!(from:, to:)
          source = translations.find_by(locale: from.to_s)
          raise I18n.t("errors.publishable.source_locale_missing", locale: from.to_s.upcase) unless source

          target = translations.find_or_initialize_by(locale: to.to_s)
          
          before_copy_draft_locale!(from: from, to: to)

          #{copy_assignments}

          after_copy_draft_locale!(from: from, to: to)
          
          target.save!
          @_translations_cache = nil
        end
      RUBY

      class_eval(generated_code, __FILE__, __LINE__)
    end
  end

  private

  def with_locale_and_fresh_cache(locale)
    I18n.with_locale(locale) do
      @_translations_cache = nil
      yield
    ensure
      @_translations_cache = nil
    end
  end
end
