# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.3.0
# Website: https://techbolic.com/

module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :activities, as: :trackable, dependent: :destroy

    # Hook into save and deletion events
    after_commit :track_changes, on: [:create, :update], if: :should_track_changes?
    after_commit :track_destruction, on: :destroy
  end

  # Returns full state serialization including nested translations/configurations and attachment references
  def snapshot_payload
    payload = attributes.dup

    # Eagerly capture multi-locale translations if the model implements Translateable
    if respond_to?(:translations)
      # Load if necessary to ensure snapshot contains absolute truth
      payload["translations"] = translations.map(&:attributes)
    end

    # Elegantly map active attachments/inline images metadata references (URLs/filenames)
    # matching competitor document versioning formats without binary payload duplication
    if respond_to?(:attachments) && (attachments.respond_to?(:attached?) ? attachments.attached? : attachments.any?)
      payload["attachment_references"] = attachments.map do |a|
        { id: a.id, filename: a.try(:filename).to_s, content_type: a.try(:content_type) }
      end
    end

    if respond_to?(:images) && (images.respond_to?(:attached?) ? images.attached? : images.any?)
      payload["image_references"] = images.map do |img|
        { id: img.id, filename: img.try(:filename).to_s, content_type: img.try(:content_type) }
      end
    end

    payload
  end

  # Returns combined attribute diffs across base table and modified translations
  def changes_payload
    diff = saved_changes.dup

    if respond_to?(:translations) && (association(:translations).loaded? || translations.any?(&:new_record?))
      translations.each do |t|
        t_changes = t.saved_changes.presence || t.changes
        if t.new_record? || t_changes.any?
          diff["translation_#{t.locale}"] = t_changes
        end
      end
    end

    diff
  end

  IGNORED_TRACKING_ATTRIBUTES = %w[
    updated_at created_at last_activity_at availability_changed_at status_changed_at
    sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip
    remember_created_at reset_password_sent_at encrypted_password reset_password_token
    confirmation_token unlock_token connection_token authentication_token
  ].freeze

  def trackable_changes
    changes_payload.except(*IGNORED_TRACKING_ATTRIBUTES)
  end

  private

  def should_track_changes?
    persisted? && (trackable_changes.any? || translations_changed_in_memory?)
  end

  def track_changes
    Activities::Recorder.call(
      trackable:  self,
      event_type: :update,
      changes:    trackable_changes
    )
  end

  def track_destruction
    Activities::Recorder.call(
      trackable:  self,
      event_type: :destroy
    )
  end

  def translations_changed_in_memory?
    return false unless respond_to?(:translations)
    return false unless association(:translations).loaded? || translations.any?(&:new_record?)

    translations.any? { |t| t.new_record? || t.changed? || t.saved_changes.any? }
  end
end
