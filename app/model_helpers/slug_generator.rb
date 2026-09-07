# frozen_string_literal: true

# Reusable slug generator for auto-generating URL-friendly identifiers from a source column.
# Works like CodeGenerator but produces human-readable slugs instead of random codes.
#
# Usage:
#   class Team < ShardRecord
#     include SlugGenerator.new(source: :name, column: :identifier, scope: :account_id)
#   end
#
#   class HelpCenter::Category < ShardRecord
#     include SlugGenerator.new(source: :name, column: :permalink, scope: :portal_id)
#   end
#
# Options:
#   source:  (Symbol) — column to slugify from (e.g. :name, :title)
#   column:  (Symbol) — column to write the slug to (e.g. :identifier, :permalink, :slug)
#   scope:   (Symbol) — uniqueness scope column (e.g. :account_id, :portal_id). Nil for global uniqueness.
#
# Collision handling: appends -2, -3, etc. within the same scope.
# Only generates on create or when the source changes and slug is blank.
class SlugGenerator < Module
  attr_accessor :source, :column, :scope

  def initialize(options = {})
    self.source = options.fetch(:source)
    self.column = options.fetch(:column, :identifier)
    self.scope  = options.fetch(:scope, nil)
  end

  def included(host)
    generator = self

    host.class_eval do
      before_validation do |instance|
        col = generator.column
        src = generator.source

        if instance.send(col).blank? && instance.send(src).present?
          instance.send("#{col}=", generator.generate_slug(instance))
        end
      end
    end
  end

  def generate_slug(instance)
    base = instance.send(source).to_s.parameterize.tr('_', '-')
    candidate = base
    counter = 1

    while slug_exists?(instance, candidate)
      counter += 1
      candidate = "#{base}-#{counter}"
    end

    candidate
  end

  private

  def slug_exists?(instance, candidate)
    query = instance.class.where(column => candidate)
    query = query.where(scope => instance.send(scope)) if scope
    query = query.where.not(id: instance.id) if instance.persisted?
    query.exists?
  end
end
