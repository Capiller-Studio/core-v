require 'rails_helper'

RSpec.describe Customers::CustomerSearcher do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    let!(:customer1) { create(:customer, account: account, name: 'Alice Smith') }
    let!(:customer2) { create(:customer, account: account, name: 'Bob Jones') }

    before do
      Customer.define_singleton_method(:search) { |*args, **kwargs| [] }
      allow(Customer).to receive(:search).and_return([customer1, customer2])
    end

    context 'without elastic_search enabled' do
      let(:service) { described_class.new(params: {}, account: account, _elastic_search: false) }

      it 'returns all customers for the account directly' do
        result = service.call
        expect(result).to include(customer1, customer2)
      end
    end

    context 'with search query' do
      let(:service) { described_class.new(params: { search: 'Alice' }, account: account, _elastic_search: true) }

      it 'calls Customer.search with the correct query' do
        expect(Customer).to receive(:search).with('Alice', anything).and_return([customer1])
        result = service.call
        expect(result).to eq([customer1])
      end
    end

    context 'when filtering by id' do
      let(:service) { described_class.new(params: { id: customer1.id }, account: account, _elastic_search: true) }

      it 'calls Customer.search with id in where clause' do
        expect(Customer).to receive(:search).with(hash_including(where: hash_including(id: customer1.id)))
        service.call
      end
    end

    context 'when ordering' do
      let(:service) { described_class.new(params: { order_by: 'name:asc' }, account: account, _elastic_search: true) }

      it 'returns customers ordered via ActiveRecord' do
        expect(Customer).not_to receive(:search)
        
        # Test the query that CustomerSearcher executes
        result = service.call
        expect(result.to_sql).to include('ORDER BY "customers"."name" ASC')
      end
    end
  end
end
