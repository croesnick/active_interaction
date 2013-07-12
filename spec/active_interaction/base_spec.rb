require 'spec_helper'

describe ActiveInteraction::Base do
  class ExampleInteraction < described_class; end

  subject(:base) { ExampleInteraction.new }

  class SubBase < described_class
    attr_reader :valid

    validates :valid,
      inclusion: {in: [true]}

    def execute
      'Execute'
    end
  end

  describe '.new(options = {})' do
    it 'sets the attributes on the return value based on the options passed' do
      expect(SubBase.new(valid: true).valid).to eq true
    end

    it 'does not allow :result as a option' do
      expect {
        SubBase.new(result: true)
      }.to raise_error ArgumentError
    end

    it "does not allow 'result' as a option" do
      expect {
        SubBase.new('result' => true)
      }.to raise_error ArgumentError
    end
  end

  describe '.run(options = {})' do
    subject(:outcome) { SubBase.run(valid: valid) }

    it 'returns an instance of the class' do
      expect(SubBase.run).to be_a SubBase
    end

    context 'validations pass' do
      let(:valid) { true }

      it 'sets `result` to the value of `execute`' do
        expect(outcome.result).to eq 'Execute'
      end
    end

    context 'validations fail' do
      let(:valid) { false }

      it 'sets result to nil' do
        expect(outcome.result).to be_nil
      end
    end
  end

  describe '.run!(options = {})' do
    subject(:result) { SubBase.run!(valid: valid) }

    context 'validations pass' do
      let(:valid) { true }

      it 'sets `result` to the value of `execute`' do
        expect(result).to eq 'Execute'
      end
    end

    context 'validations fail' do
      let(:valid) { false }

      it 'throws an error' do
        expect {
          result
        }.to raise_error ActiveInteraction::InteractionInvalid
      end
    end
  end

  describe 'method_missing(filter_type, *args, &block)' do
    context 'it catches valid filter types' do
      class BoolTest < described_class
        boolean :test

        def execute; end
      end

      it 'adds an attr_reader for the method' do
        expect(BoolTest.new).to respond_to :test
      end

      it 'adds an attr_writer for the method' do
        expect(BoolTest.new).to respond_to :test=
      end
    end

    context 'allows multiple methods to be defined' do
      class BoolTest < described_class
        boolean :test1, :test2

        def execute; end
      end

      it 'creates a attr_reader for both methods' do
        expect(BoolTest.new).to respond_to :test1
        expect(BoolTest.new).to respond_to :test2
      end

      it 'creates a attr_writer for both methods' do
        expect(BoolTest.new).to respond_to :test1
        expect(BoolTest.new).to respond_to :test2
      end
    end

    context 'does not stop other missing methods from erroring out' do
      it 'throws a missing method error for non-filter types' do
        expect {
          class FooTest < described_class
            foo :test

            def execute; end
          end
        }.to raise_error NoMethodError
      end
    end
  end

  its(:new_record?) { should be_true  }
  its(:persisted?)  { should be_false }

  describe '#execute' do
    it 'throws a NotImplementedError' do
      expect { base.execute }.to raise_error NotImplementedError
    end

    context 'integration' do
      class TestInteraction < described_class
        boolean :b
        def execute; end
      end

      it 'raises an error with invalid option' do
        expect {
          TestInteraction.run!(b: 0)
        }.to raise_error ActiveInteraction::InteractionInvalid
      end

      it 'does not raise an error with valid option' do
        expect { TestInteraction.run!(b: true) }.to_not raise_error
      end

      it 'requires required options' do
        expect(TestInteraction.run b: nil).to_not be_valid
      end
    end
  end
end
