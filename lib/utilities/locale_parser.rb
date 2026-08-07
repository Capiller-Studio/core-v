# frozen_string_literal: true

module Utilities
  class LocaleParser
    LANGUAGE_MAPPING = {
      "english" => "en",
      "spanish" => "es",
      "french" => "fr",
      "german" => "de",
      "italian" => "it",
      "portuguese" => "pt",
      "dutch" => "nl",
      "russian" => "ru",
      "chinese" => "zh",
      "japanese" => "ja",
      "korean" => "ko",
      "arabic" => "ar",
      "hindi" => "hi",
      "bengali" => "bn",
      "urdu" => "ur",
      "turkish" => "tr",
      "vietnamese" => "vi",
      "thai" => "th",
      "polish" => "pl",
      "indonesian" => "id"
    }.freeze

    def self.parse(input)
      return nil if input.blank?

      normalized = input.to_s.strip.downcase

      # 1. Check if it's a known full language name
      if LANGUAGE_MAPPING.key?(normalized)
        return LANGUAGE_MAPPING[normalized]
      end

      # 2. Fix underscores to hyphens (standard BCP 47 format, e.g., en_US -> en-US)
      normalized.tr!("_", "-")

      # 3. Format casing properly: en-us -> en-US, pt-br -> pt-BR
      parts = normalized.split("-")
      if parts.size >= 2
        parts[0] = parts[0].downcase
        parts[1] = parts[1].upcase
        normalized = parts[0..1].join("-")
      else
        normalized = parts[0].downcase
      end

      # We accept anything else since Customer/Conversation locales can be anything
      normalized
    end
  end
end
