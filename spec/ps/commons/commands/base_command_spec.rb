# frozen_string_literal: true

class PageSizeValidator < ActiveModel::Validator
  def validate(record)
    return unless record.page_size > 20

    record.errors.add :base, 'page size must be less than or equal to 20'
  end
end

RSpec.describe Ps::Commons::BaseCommand do
  shared_examples 'args valid?' do
    it { expect(run_command.args).to be_valid }
    it { expect(run_command.args.errors.full_messages).to be_empty }
  end

  shared_examples 'args invalid?' do |error_message|
    it { expect(run_command.args).to be_invalid }
    it { expect(run_command.args.errors.full_messages).to include(error_message) }
  end

  shared_examples 'command valid?' do
    it { expect(run_command).to be_valid }
    it { expect(run_command.errors.full_messages).to be_empty }
  end

  shared_examples 'command invalid?' do |error_message|
    it { expect(run_command).to be_invalid }
    it { expect(run_command.errors.full_messages).to include(error_message) }
  end

  shared_examples 'command success?' do
    it { expect(run_command).to be_success }
  end

  shared_examples 'command failure?' do
    it { expect(run_command).to be_failure }
  end

  let(:opts) { {} }

  describe '#run' do
    subject { run_command }

    let(:run_command) { command.run(**opts) }

    context 'when command is missing call method' do
      let(:command) { Class.new(described_class) }

      it { expect { subject }.to raise_error NoMethodError, 'implement the call method in your command object' }
    end

    context 'when args is not defined' do
      let(:command) do
        Class.new(described_class) do
          attr_reader :output

          def call
            @output = 'hello'
          end
        end
      end

      it_behaves_like 'args valid?'
      it_behaves_like 'command valid?'
      it_behaves_like 'command success?'

      it { is_expected.to have_attributes(output: 'hello') }
    end

    context 'when args are defined' do
      subject { run_command }

      let(:command) do
        Class.new(described_class) do
          # Argument definition and validation
          args do
            attribute :name
            attribute :page_size, :integer, default: 20
            attribute :dry_run, :boolean, default: false

            validates :name, presence: true
            validates_with PageSizeValidator
          end

          # Command definition and validation
          attr_reader :output

          # this validation is specifically to help test invalid commands
          validates :output, presence: true, if: -> { args.valid? }

          def call
            return if args.invalid?

            return if args.dry_run

            @output = { name: args.name, page_size: args.page_size }
          end
        end
      end

      context 'when all options provided' do
        let(:opts) { { name: 'John', page_size: 10 } }

        it_behaves_like 'args valid?'
        it_behaves_like 'command valid?'
        it_behaves_like 'command success?'

        it { is_expected.to have_attributes(output: { name: 'John', page_size: 10 }) }
      end

      context 'when required option provided' do
        let(:opts) { { name: 'John' } }

        it_behaves_like 'args valid?'
        it_behaves_like 'command valid?'
        it_behaves_like 'command success?'

        it { is_expected.to have_attributes(output: { name: 'John', page_size: 20 }) }
      end

      context 'when argument validation fails - name is missing' do
        let(:opts) { { page_size: 10 } }

        it_behaves_like 'args invalid?', "Name can't be blank"
        it_behaves_like 'command valid?'
        it_behaves_like 'command failure?'

        it { is_expected.to have_attributes(output: nil) }
      end

      context 'when argument validation fails - invalid page size' do
        let(:opts) { { name: 'John', page_size: 30 } }

        it_behaves_like 'args invalid?', 'page size must be less than or equal to 20'
        it_behaves_like 'command valid?'
        it_behaves_like 'command failure?'

        it { is_expected.to have_attributes(output: nil) }
      end

      context 'when arguments are valid, but the command is invalid' do
        let(:opts) { { name: 'John', dry_run: true } }

        it_behaves_like 'args valid?'
        it_behaves_like 'command invalid?', "Output can't be blank"
        it_behaves_like 'command failure?'

        it { is_expected.to have_attributes(output: nil) }
      end
    end
  end
end
