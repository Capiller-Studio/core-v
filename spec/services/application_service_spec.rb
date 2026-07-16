require 'rails_helper'

RSpec.describe ApplicationService do
  describe '.call' do
    let(:service_class) do
      Class.new(ApplicationService) do
        def initialize(arg1, arg2: nil)
          @arg1 = arg1
          @arg2 = arg2
        end

        def call
          "Result: #{@arg1}, #{@arg2}"
        end
      end
    end

    it 'instantiates the class and calls #call with the provided arguments' do
      expect(service_class).to receive(:new).with('value1', arg2: 'value2').and_call_original
      result = service_class.call('value1', arg2: 'value2')
      
      expect(result).to eq('Result: value1, value2')
    end
  end
end
