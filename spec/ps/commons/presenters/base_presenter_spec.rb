# frozen_string_literal: true

class FakePresenter < Ps::Commons::BasePresenter
  outputs :required_output, required: true
  outputs :optional_output
end

RSpec.describe Ps::Commons::BasePresenter do
  describe '#initialize' do
    subject { described_class.new }

    it { is_expected.not_to be_nil }
  end

  describe '#output_contract' do
    subject { presenter.new.output_contract }

    context 'when optional and required outputs are defined' do
      let(:presenter) { FakePresenter }

      it { is_expected.to include(required_output: { name: :required_output, required: true }, optional_output: { name: :optional_output, required: false }) }
    end

    context 'when optional is redefined to required' do
      let(:presenter) do
        Class.new(FakePresenter) do
          outputs :optional_output, required: true
        end
      end

      it { is_expected.to include(required_output: { name: :required_output, required: true }, optional_output: { name: :optional_output, required: true }) }
    end

    context 'when additional outputs are added' do
      let(:presenter) do
        Class.new(FakePresenter) do
          outputs :a, :b
          outputs :c, required: true
        end
      end

      it do
        expect(subject).to include(
          required_output: { name: :required_output, required: true },
          optional_output: { name: :optional_output, required: false },
          a: { name: :a, required: false },
          b: { name: :b, required: false },
          c: { name: :c, required: true }
        )
      end
    end

    context 'when deep nested classes are used' do
      let(:presenter) do
        child = Class.new(FakePresenter)

        Class.new(child) do
          outputs :deep_child
        end
      end

      it do
        expect(subject).to include(
          required_output: { name: :required_output, required: true },
          optional_output: { name: :optional_output, required: false },
          deep_child: { name: :deep_child, required: false }
        )
      end
    end
  end

  describe '#present' do
    subject { presenter.present }

    context 'without any arguments' do
      let(:presenter) do
        Class.new(FakePresenter) do
          def call
            self.optional_output = 'something'
            self.required_output = 'must be set'
          end
        end
      end

      it { is_expected.to be_a(OpenStruct) }
      it { is_expected.to be_a(OpenStruct).and have_attributes(required_output: 'must be set', optional_output: 'something') }
    end

    context 'with positional arguments' do
      subject { presenter.present('Bob', 'Marley') }

      let(:presenter) do
        Class.new(FakePresenter) do
          def initialize(first_name, last_name)
            super
            @first_name = first_name
            @last_name = last_name
          end

          def call
            self.required_output = "#{@first_name} #{@last_name}"
          end
        end
      end

      it {
        expect(subject).to be_a(OpenStruct).and have_attributes(required_output: 'Bob Marley', optional_output: nil)
      } # , optional_output: nil).  THIS DOES NOT WORK, THERE is BUG that needs to be handled via class inheritance

      it { expect(subject.optional_output).to be_nil }
    end

    context 'with an options contract' do
      subject { presenter.present(critter1: 'Fox', critter2: 'Dog') }

      let(:presenter) do
        Class.new(FakePresenter) do
          contract do
            attribute :critter1
            attribute :critter2
            attribute :page_size, :int, default: 20
          end

          def call
            self.optional_output = opts.page_size
            self.required_output = "The quick brow #{opts.critter1} jumped over the lazy #{opts.critter2}"
          end
        end
      end

      it do
        expect(subject)
          .to be_a(OpenStruct)
          .and have_attributes(required_output: 'The quick brow Fox jumped over the lazy Dog')
          .and have_attributes(optional_output: 20)
      end
    end

    context 'when parent -> required output property is not set' do
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
