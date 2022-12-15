# frozen_string_literal: true

class MissingCallMethodCommand < Ps::Commons::BaseCommand
end

# class NoScopeQuery < Ps::Commons::Query
#   def call
#   end
# end

RSpec.describe Ps::Commons::BaseCommand do
  let(:opts) { {} }

  describe '#run' do
    subject { command.run(**opts) }

    context 'when misconfigured' do
      context 'with missing call method' do
        let(:command) do
          Class.new(described_class)
        end

        it { expect { subject }.to raise_error NoMethodError, 'implement the call method in your command object' }
      end
    end

    context 'when contract is defined' do
      subject { command.run(**opts).output }

      let(:command) do
        Class.new(described_class) do
          attr_reader :output

          contract do
            attribute :name
            attribute :page_size, :int, default: 20
          end

          def call
            @output = { name: opts.name, page_size: opts.page_size }
          end
        end
      end

      context 'when no options provided' do
        it { is_expected.to eq(name: nil, page_size: 20) }
      end

      context 'when options provided' do
        let(:opts) { { name: 'John', page_size: 10 } }

        it { is_expected.to eq(name: 'John', page_size: 10) }
      end
    end
  end
end
