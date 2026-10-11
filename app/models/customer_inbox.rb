# frozen_string_literal: true
# == Schema Information
#
# Table name: customer_inboxes
#
#  id               :uuid             not null, primary key
#  external_id      :string           not null
#  connection_token :string           not null
#  customer_id      :uuid             not null
#  inbox_id         :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_customer_inboxes_on_connection_token          (connection_token) UNIQUE
#  index_customer_inboxes_on_customer_id               (customer_id)
#  index_customer_inboxes_on_customer_id_and_inbox_id  (customer_id,inbox_id) UNIQUE
#  index_customer_inboxes_on_external_id               (external_id)
#  index_customer_inboxes_on_inbox_id                  (inbox_id)
#

class CustomerInbox < ShardRecord
  belongs_to :customer
  belongs_to :inbox
  has_many :customer_devices, dependent: :delete_all

  # TODO: Would be unique system wide. We would prepend account id
  has_secure_token :connection_token
end
