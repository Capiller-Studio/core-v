# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Deletable
  extend ActiveSupport::Concern

  class_methods do
    def identifying_columns(*columns)
      cols = columns.map(&:to_sym).freeze
      define_singleton_method(:deletable_identifying_columns) { cols }
    end

    def deletable_identifying_columns
      [].freeze
    end
  end

  included do
    delegate :deletable_identifying_columns, to: :class
  end

  # Stage 1: Self-service deactivation when deletion is requested
  def deactivate_for_deletion!(metadata = {})
    raise(ActiveRecord::RecordInvalid, self) if deleted?

    transaction do
      deletion_meta = {
        "requested_at" => Time.current.iso8601
      }.merge(metadata.stringify_keys)

      merged_data = (data || {}).deep_merge("deletion" => deletion_meta)

      self.status = :pending_deletion
      self.data = merged_data
      save!(validate: false)

      after_deactivate_for_deletion
    end
  end

  # Stage 2: Soft deletion performed by staff in backoffice console
  def mark_as_deleted!(metadata = {})
    transaction do
      archived = {
        "deleted_at" => Time.current.iso8601
      }.merge(metadata.stringify_keys)

      deletable_identifying_columns.each do |col|
        archived[col.to_s] = self[col]
      end

      archived["name"] = try(:name) if respond_to?(:name)

      merged_data = (data || {}).deep_merge("archived_identity" => archived)

      update_attributes = {
        status: self.class.statuses[:deleted],
        data: merged_data
      }

      deletable_identifying_columns.each do |col|
        update_attributes[col] = nil
      end

      update_columns(update_attributes)
      reload

      after_mark_as_deleted
    end
  end

  # Restoration by staff in backoffice console
  def restore_active!
    transaction do
      before_restore_active

      if data&.dig("archived_identity").present?
        archived = data["archived_identity"]

        deletable_identifying_columns.each do |col|
          val = archived[col.to_s]
          next if val.blank?

          if self.class.where(col => val).where.not(id: id).exists?
            errors.add(col, "is already taken by another active record and cannot be restored")
            raise(ActiveRecord::RecordInvalid, self)
          end

          self[col] = val
        end
      end

      self.status = :active
      save!

      after_restore_active
    end
  end

  # Default lifecycle hooks for model-specific cleanup/restoration
  def after_deactivate_for_deletion; end
  def after_mark_as_deleted; end
  def before_restore_active; end
  def after_restore_active; end
end
