# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

class ActivityLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :logs, retry: 3

  def perform(account_id, params = {})
    params = params.with_indifferent_access
    account = Account.find(account_id)

    account.with_shard do
      # Create the Activity record using the snapshot provided by the Recorder
      Activity.create!(
        account_id:       account_id,
        trackable_type:   params[:trackable_type],
        trackable_id:     params[:trackable_id],
        actor_type:       params[:actor_type],
        actor_id:         params[:actor_id],
        event_key:        "#{params[:trackable_type].underscore}.#{params[:event_type]}",
        object_changes:   params[:changes],
        object_snapshot:  params[:snapshot], # Use the snapshot captured by the recorder
        metadata:         params[:metadata]
      )
    end
  end
end
