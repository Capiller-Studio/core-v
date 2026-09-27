# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'plans:update rake task' do # rubocop:disable RSpec/DescribeClass
  before do
    Rake.application.rake_require('tasks/plans', [Core::Engine.root.join('lib').to_s])
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task['plans:update'].reenable
  end

  it 'updates existing plans with latest pricing and features from PlanSeeder' do
    # Create an outdated Parabolic plan
    parabolic = create(:plan, name: Plan::PARABOLIC, currency: 'USD', base_price: 49, annual_price: 44, features: { 'sso' => true })

    expect {
      Rake::Task['plans:update'].invoke
    }.to output(/Synchronizing and Updating Plans from PlanSeeder/).to_stdout

    parabolic.reload
    expect(parabolic.base_price).to eq(29)
    expect(parabolic.annual_price).to eq(26)
    expect(parabolic.features['sso']).to be(false)
    expect(parabolic.features['scim']).to be(false)
  end

  it 'is idempotent when run repeatedly' do
    Rake::Task['plans:update'].invoke

    Rake::Task['plans:update'].reenable
    expect {
      Rake::Task['plans:update'].invoke
    }.to output(/0 updated, 16 unchanged/).to_stdout
  end
end
