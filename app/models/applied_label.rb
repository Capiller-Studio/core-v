class AppliedLabel < ShardRecord
  belongs_to :label
  belongs_to :labelable, polymorphic: true

  validates :label_id, uniqueness: { scope: [:labelable_id, :labelable_type] }

  before_validation :set_account_id, on: :create

  private

  def set_account_id
    self.account_id ||= labelable&.account_id || label&.account_id
  end
end
