# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Activities
  class RevertService < ApplicationService
    attr_reader :activity, :trackable, :mode

    def initialize(activity:, mode: :undo)
      @activity  = activity
      @trackable = activity.trackable
      @mode      = mode.to_sym
    end

    def call
      return false unless trackable

      trackable.transaction do
        if mode == :rollback
          apply_full_rollback!
          log_reversion_event(:rolled_back)
        else
          apply_selective_undo!
          log_reversion_event(:undone)
        end

        trackable.save!
      end

      true
    rescue StandardError => e
      Rails.logger.error("Activities::RevertService Error: #{e.message}")
      false
    end

    private

    # Point-in-Time Rollback: Overwrites current state completely with historical snapshot
    def apply_full_rollback!
      snapshot = activity.object_snapshot.dup
      translations_payload = snapshot.delete("translations")

      # 1. Restore base attributes
      trackable.assign_attributes(snapshot.except("id", "created_at", "updated_at"))

      # 2. Deep restore multi-locale translations if present
      if translations_payload.is_a?(Array) && trackable.respond_to?(:translations)
        # Clear existing unlisted translations or sync attributes cleanly
        existing_locales = translations_payload.map { |tp| tp["locale"] }
        trackable.translations.each do |t|
          t.mark_for_destruction unless existing_locales.include?(t.locale.to_s)
        end

        translations_payload.each do |t_attrs|
          loc = t_attrs["locale"].to_s
          target = trackable.translations.find { |t| t.locale.to_s == loc } || trackable.translations.build(locale: loc)
          target.assign_attributes(t_attrs.except("id", "created_at", "updated_at", "article_id"))
        end
      end
    end

    # Non-Destructive Undo: Selectively computes and applies the inverse diff of modified fields
    def apply_selective_undo!
      changes = activity.object_changes.dup

      changes.each do |key, diff|
        if key.start_with?("translation_")
          # Handle nested translation inverse diff
          locale = key.sub("translation_", "")
          if trackable.respond_to?(:translations)
            target = trackable.translations.find { |t| t.locale.to_s == locale }
            if target && diff.is_a?(Hash)
              diff.each do |t_field, values|
                # values[0] represents the state before the update
                target.send("#{t_field}=", values.is_a?(Array) ? values[0] : nil) if target.respond_to?("#{t_field}=")
              end
            end
          end
        elsif trackable.respond_to?("#{key}=")
          # Handle base table field inverse diff
          trackable.send("#{key}=", diff.is_a?(Array) ? diff[0] : nil)
        end
      end
    end

    def log_reversion_event(action_type)
      Activities::Recorder.call(
        trackable:  trackable,
        event_type: action_type,
        changes:    { "target_activity_id" => activity.id, "reversion_mode" => mode }
      )
    end
  end
end
