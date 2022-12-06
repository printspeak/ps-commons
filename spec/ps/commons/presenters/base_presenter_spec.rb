# frozen_string_literal: true

class FakePresenter < Ps::Commons::BasePresenter
  outputs :required_output, required: true
  outputs :optional_output
end

class GoodWithInitializerFakePresenter < FakePresenter
  def initialize(something)
    # puts "inside GoodWithInitializerFakePresenter#initialize - before super"
    super
    # puts "inside GoodWithInitializerFakePresenter#initialize"
    @something = something
  end

  def call
    # puts "inside GoodWithInitializerFakePresenter#call"
    self.required_output = @something
  end
end

class GoodWithArgContractFakePresenter < FakePresenter
  contract do
    attribute :something
    attribute :page_size, :int, default: 20
  end

  def call
    # puts 'inside GoodWithArgContractFakePresenter#call'
    self.required_output = opts.something
    self.optional_output = opts.page_size
  end
end

RSpec.describe Ps::Commons::BasePresenter do
  describe '#initialize' do
    subject { described_class.new }

    it { is_expected.not_to be_nil }
  end

  describe '#present' do
    subject { presenter.present }

    context 'without positional arguments' do
      let(:presenter) do
        Class.new(FakePresenter) do
          def call
            self.optional_output = 'something'
            self.required_output = optional_output
          end
        end
      end

      it { is_expected.to be_a(OpenStruct) }
      it { is_expected.to be_a(OpenStruct).and have_attributes(required_output: 'something', optional_output: 'something') }
    end

    context 'with positional arguments' do
      # defined method initialize
      # defined method initialize - before super
      # defined method initialize - after super
      # defined method call - before super
      # defined method call - after super
      # defined method call - after validate_outputs
      subject { GoodWithInitializerFakePresenter.present('something') }

      it { is_expected.to be_a(OpenStruct).and have_attributes(required_output: 'something') }
      it { expect(subject.optional_output).to be_nil }
    end

    context 'with contractual options' do
      subject { GoodWithArgContractFakePresenter.present(something: 'something') }

      it do
        expect(subject)
          .to be_a(OpenStruct)
          .and have_attributes(required_output: 'something')
          .and have_attributes(optional_output: 20)
      end
    end

    context 'when parents required output property is not set' do
      let(:presenter) do
        Class.new(FakePresenter) do
          def call
            self.optional_output = 'something'
          end
        end
      end

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'when call method is missing' do
      let(:presenter) { Class.new(FakePresenter) }

      it { expect { subject }.to raise_error(NoMethodError) }
    end
  end
end
