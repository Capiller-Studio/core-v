# frozen_string_literal: true

class EmailTemplateLayout < ShardRecord
  include Translateable

  TRANSLATABLE_FIELDS = %i[body].freeze

  belongs_to :account
  has_many :attachments, as: :resource, dependent: :destroy

  translates(*TRANSLATABLE_FIELDS)
end
