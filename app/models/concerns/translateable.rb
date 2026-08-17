# frozen_string_literal: true

module Translateable
  extend ActiveSupport::Concern

  included do
    @translation_model = "#{self}Translation".freeze

    # rubocop:disable Rails/ReflectionClassName, Rails/HasManyOrHasOneDependent, Rails/InverseOf
    has_many :translations, class_name: @translation_model, dependent: :destroy, autosave: true
    accepts_nested_attributes_for :translations, allow_destroy: true

    # Eager loadable associations for specific locales
    has_one :current_translation, -> { where(locale: I18n.locale) }, class_name: @translation_model
    has_one :fallback_translation, ->(record) { where(locale: record.fallback_locale) }, class_name: @translation_model
    # rubocop:enable Rails/ReflectionClassName, Rails/HasManyOrHasOneDependent, Rails/InverseOf

    def self.translates(*attributes)
      attributes.each do |attribute|
        define_method(attribute) do
          translation_for(attribute)
        end

        define_method("#{attribute}=") do |value|
          # Prioritize finding in existing collection to avoid duplicate builds
          target = I18n.locale.to_s
          translation = translations.find { |t| t.locale.to_s == target } || translations.build(locale: target)
          translation.send("#{attribute}=", value)

          # Reset cache if value is changed
          @_translations_cache = nil
        end
      end
    end
  end

  # Default fallback logic. Models can override this.
  # e.g. def fallback_locale; account.locale; end
  def fallback_locale
    I18n.default_locale
  end

  def translation_for(attribute)
    # 1. Check memoized cache
    cache_key = "#{I18n.locale}_#{attribute}"
    @_translations_cache ||= {}
    return @_translations_cache[cache_key] if @_translations_cache.key?(cache_key)

    # 2. Try current locale
    target = I18n.locale.to_s
    translation = find_translation_in_memory(target)

    # 3. Try fallback locale if current is missing
    if translation&.send(attribute).blank?
      fallback = fallback_locale.to_s
      translation = find_translation_in_memory(fallback) if fallback != target
    end

    @_translations_cache[cache_key] = translation&.send(attribute)
  end

  def translated_to?(locale)
    translations.any? { |t| t.locale.to_s == locale.to_s }
  end

  private

  def find_translation_in_memory(locale)
    # Check if the specific association is loaded to avoid N+1 or loading all
    if locale == I18n.locale.to_s && association(:current_translation).loaded?
      return current_translation
    end

    if locale == fallback_locale.to_s && association(:fallback_translation).loaded?
      return fallback_translation
    end

    # Fallback to scanning the whole collection if it's already loaded
    if association(:translations).loaded?
      return translations.find { |t| t.locale.to_s == locale }
    end

    # If nothing is loaded, we trigger a specific query for just this locale
    # This prevents loading ALL translations if the dev forgot to use includes
    translations.find_by(locale: locale)
  end
end
