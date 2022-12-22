# frozen_string_literal: true

RSpec.describe Ps::Commons::BaseCommand do
  let(:opts) { {} }

  describe '#run' do
    subject { command.run(**opts) }

    context 'when misconfigured' do
      context 'with missing call method' do
        let(:command) { Class.new(described_class) }

        it { expect { subject }.to raise_error NoMethodError, 'implement the call method in your command object' }
      end
    end

    context 'when contract is not defined' do
      let(:command) do
        Class.new(described_class) do
          def call; end
        end
      end

      describe '.valid?' do
        subject { command.run(**opts).valid? }

        it { is_expected.to be true }
      end
    end

    context 'when contract is defined' do
      subject { command.run(**opts).output }

      let(:command) do
        Class.new(described_class) do
          attr_reader :output

          contract do
            attribute :name, required: true
            attribute :page_size, :int, default: 20
          end

          contract_validate do
            validation_errors << 'page size must be less than or equal to 20' if opts.page_size > 20
          end

          def call
            @output = { name: opts.name, page_size: opts.page_size }
          end
        end
      end

      context 'when all options provided' do
        let(:opts) { { name: 'John', page_size: 10 } }

        it { is_expected.to eq(name: 'John', page_size: 10) }

        describe '.valid?' do
          subject { command.run(**opts).valid? }

          it { is_expected.to be true }
        end
      end

      context 'when only required option provided' do
        let(:opts) { { name: 'John' } }

        it { is_expected.to eq(name: 'John', page_size: 20) }
      end

      context 'when required option not provided' do
        it { is_expected.to be_nil }

        describe '.valid?' do
          subject { command.run(**opts).valid? }

          it { is_expected.to be false }
        end

        describe '#validation_errors' do
          subject { command.run(**opts).validation_errors }

          it { is_expected.to include('name is required') }
        end
      end

      context 'when custom contract validation fails' do
        let(:opts) { { name: 'John', page_size: 30 } }

        it { is_expected.to be_nil }

        describe '.valid?' do
          subject { command.run(**opts).valid? }

          it { is_expected.to be false }
        end

        describe '#validation_errors' do
          subject { command.run(**opts).validation_errors }

          it { is_expected.to include('page size must be less than or equal to 20') }
        end
      end
    end

    describe '#success?' do
      subject { command.run(**opts) }

      let(:command) do
        Class.new(described_class) do
          attr_reader :was_i_set

          contract do
            attribute :name, required: true
          end

          def call
            @was_i_set = opts.name

            # Only John is successful
            self.success = opts.name == 'John'
          end
        end
      end

      context 'when required option not provided' do
        it { is_expected.to have_attributes(success: false, was_i_set: nil) }
        it { is_expected.not_to be_successful }
      end

      context 'when required option provided but the call is not successful' do
        let(:opts) { { name: 'Jane' } }

        it { is_expected.to have_attributes(success: false, was_i_set: 'Jane') }
        it { is_expected.not_to be_successful }
      end

      context 'when required option provided and the call is successful' do
        let(:opts) { { name: 'John' } }

        it { is_expected.to have_attributes(success: true, was_i_set: 'John') }
        it { is_expected.to be_successful }
      end
    end
  end
end
