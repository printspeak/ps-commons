# frozen_string_literal: true

class BadWordValidator < ActiveModel::Validator
  BAD_WORDS = %w[ass tits doodle].freeze
  def validate(record)
    return unless BAD_WORDS.any? { |s| s.casecmp(record.title) == 0 || s.casecmp(record.name) == 0 }

    record.errors.add :base, 'Bad language is not acceptable'
  end
end

RSpec.describe Ps::Commons::Args do
  let(:args) { described_class.new }

  describe '.define_class' do
    let(:defined_class) { described_class.define_class('Holiday', &block) }
    let(:block) { proc {} }

    describe '.model_name' do
      subject { defined_class.model_name }

      it { is_expected.to eq('Holiday') }
    end

    context 'when instantiated' do
      subject { instance }

      let(:instance) { defined_class.new(**args) }
      let(:args) { {} }

      it { is_expected.to be_a defined_class }
      it { is_expected.to be_valid }

      context 'when attr_accessor is used' do
        let(:args) { { name: 'David' } }

        let(:block) do
          proc do
            attr_accessor :name
          end
        end

        it { is_expected.to have_attributes(name: 'David') }
      end

      context 'when attribute with type coercion' do
        let(:args) { { age: '33' } }

        let(:block) do
          proc do
            attribute :age, :integer
          end
        end

        it { is_expected.to have_attributes(age: 33) }
      end

      context 'when attribute with default' do
        let(:block) do
          proc do
            attribute :type, :string, default: 'unknown'
          end
        end

        it { is_expected.to have_attributes(type: 'unknown') }
      end

      context 'when using validation' do
        before { instance.valid? }

        context 'when presence validation with minium length of 3 for name' do
          let(:args) { { name: 'Jo' } }

          let(:block) do
            proc do
              attr_accessor :name

              validates :name, presence: true, length: { minimum: 3 }
            end
          end

          it { is_expected.not_to be_valid }
          it { is_expected.to have_attributes(name: 'Jo') }
          it { expect(instance.errors.full_messages).to include('Name is too short (minimum is 3 characters)') }
        end

        context 'when custom validate_with' do
          let(:block) do
            proc do
              attr_accessor :title, :name

              validates_with BadWordValidator
            end
          end

          context 'when title is bad' do
            let(:args) { { title: 'Ass', name: 'Hole' } }

            it { is_expected.not_to be_valid }
            it { expect(instance.errors.full_messages).to include('Bad language is not acceptable') }
          end

          context 'when name is bad' do
            let(:args) { { title: 'Mr', name: 'Doodle' } }

            it { is_expected.not_to be_valid }
            it { expect(instance.errors.full_messages).to include('Bad language is not acceptable') }
          end
        end
      end
    end
  end

  # Uncomment this to play around with examples
  # describe '#playground' do
  #   it do
  #     klass = described_class.define_class('Person') do
  #       # If you need custom includes, you can add them
  #       include ActiveModel::Validations::Callbacks

  #       attr_accessor :title, :name, :age, :email, :phone_number, :shirt_size

  #       attribute :date_of_birth, :date
  #       attribute :employed, :boolean

  #       validates :name, presence: true, length: { minimum: 3 }
  #       validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true }
  #       validates :shirt_size, inclusion: { in: %w[small medium large], message: '%<value>s is not a valid size', allow_blank: true }

  #       validates_with BadWordValidator

  #       after_validation :jobs_for_everyone

  #       def jobs_for_everyone
  #         self.employed = true if employed.nil?
  #       end
  #     end

  #     people = [
  #       klass.new(name: 'John', age: 29),
  #       klass.new(name: 'Lisa', age: 33, email: 'lisa@gmail.com'),
  #       klass.new(name: 'Bob', age: 31, email: ''),
  #       klass.new(age: 31, email: 'bob@gmail.com'),
  #       klass.new(name: 'Alice', shirt_size: 'small'),
  #       klass.new(name: 'David', shirt_size: 'large'),
  #       klass.new(name: 'James', shirt_size: 'xlarge'),
  #       klass.new(title: 'Mr', name: 'Cruwys', email: 'david@sample.com'),
  #       klass.new(title: 'Ass', name: 'Hole', email: 'a@a.com'),
  #       klass.new(title: 'Little', name: 'Doodle', email: 'a@a.com'),
  #       klass.new(name: 'JP', email: 'john_paul@a.com'),
  #       klass.new(name: 'Fred', email: 'fred@a.com', employed: 'F', date_of_birth: '1980-01-17'),
  #       klass.new(name: 'Sally', email: 'sally@a.com', employed: 'yes', date_of_birth: '1980-17-01')
  #     ]

  #     people.each do |person|
  #       puts "#{person.title} #{person.name} is #{person.age} years old, this record is #{person.valid? ? 'valid' : 'INVALID'}".squish
  #       puts person.as_json
  #       puts person.errors.full_messages if person.invalid?
  #       puts '-' * 80
  #     end
  #   end
  # end
end
