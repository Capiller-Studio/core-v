# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_field_resources
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  position          :integer
#  required_override :boolean
#  resource_id       :uuid             not null
#  resource_type     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  custom_field_id   :uuid             not null
#
# Indexes
#
#  idx_custom_field_resources_unique                  (custom_field_id,resource_type,resource_id) UNIQUE
#  index_custom_field_resources_on_custom_field_id    (custom_field_id)
#  index_custom_field_resources_on_resource           (resource_type,resource_id)
#
# Foreign Keys
#
#  fk_rails_...  (custom_field_id => custom_fields.id) ON DELETE => cascade
#
class CustomFieldResource < ShardRecord
  belongs_to :custom_field
  belongs_to :resource, polymorphic: true

  # resource is polymorphic — can be any model that uses custom fields:
  #   "Channel::ContactForm" → field appears in that specific contact form
  #   "Account"              → field appears in the customer profile sidebar (future)
  #
  # position overrides the CustomField's global default position for this specific resource.
  # required_override: nil    = use CustomField#required (default)
  #                   true    = force required in this resource context
  #                   false   = force optional in this resource context

  # configurations jsonb — per-resource display overrides:
  # {
  #   "hidden"    => false,  (hide in this specific context, e.g. shown in form but not profile)
  #   "read_only" => false,  (display but prevent editing in this context)
  #   "width"     => "full"  (UI layout override: "full" | "half")
  # }
end
