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

  it do
    klass = described_class.define_class('Person') do
      # If you need custom includes, you can add them
      include ActiveModel::Validations::Callbacks

      attr_accessor :title, :name, :age, :email, :phone_number, :shirt_size

      attribute :date_of_birth, :date
      attribute :employed, :boolean

      validates :name, presence: true, length: { minimum: 3 }
      validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true }
      validates :shirt_size, inclusion: { in: %w[small medium large], message: '%<value>s is not a valid size', allow_blank: true }

      validates_with BadWordValidator

      after_validation :jobs_for_everyone

      def jobs_for_everyone
        self.employed = true if employed.nil?
      end
    end

    people = [
      klass.new(name: 'John', age: 29),
      klass.new(name: 'Lisa', age: 33, email: 'lisa@gmail.com'),
      klass.new(name: 'Bob', age: 31, email: ''),
      klass.new(age: 31, email: 'bob@gmail.com'),
      klass.new(name: 'Alice', shirt_size: 'small'),
      klass.new(name: 'David', shirt_size: 'large'),
      klass.new(name: 'James', shirt_size: 'xlarge'),
      klass.new(title: 'Mr', name: 'Cruwys', email: 'david@sample.com'),
      klass.new(title: 'Ass', name: 'Hole', email: 'a@a.com'),
      klass.new(title: 'Little', name: 'Doodle', email: 'a@a.com'),
      klass.new(name: 'JP', email: 'john_paul@a.com'),
      klass.new(name: 'Fred', email: 'fred@a.com', employed: 'F', date_of_birth: '1980-01-17'),
      klass.new(name: 'Sally', email: 'sally@a.com', employed: 'yes', date_of_birth: '1980-17-01')
    ]

    people.each do |person|
      puts "#{person.title} #{person.name} is #{person.age} years old, this record is #{person.valid? ? 'valid' : 'INVALID'}".squish
      puts person.as_json
      puts person.errors.full_messages if person.invalid?
      puts '-' * 80
    end
  end

  describe '.define_class' do
    subject { described_class.define_class('Holiday', &block).new }

    let(:block) { proc {} }

    it { is_expected.to be_a described_class }
  end

  describe '.create' do
    subject { args_object }

    let(:args_object) { described_class.create(args_class, **opts) }
    let(:args_class) { described_class.define_class('Holiday', &block) }
    # let(:class_name) { 'Holiday' }
    let(:block) { proc {} }
    let(:opts) { {} }

    it { is_expected.to be_a described_class }

    context 'when using validates' do
      before { args_object.valid? }

      let(:block) do
        proc do
          attr_accessor :name

          validates :name, presence: true

          def self.model_name
            ActiveModel::Name.new(self, nil, 'Holiday')
          end
        end
      end

      context 'when not provided' do
        describe '.valid?' do
          subject { args_object }

          it { is_expected.not_to be_valid }
        end

        describe '.errors' do
          subject { args_object.errors.full_messages }

          it { is_expected.to include "Name can't be blank" }
        end
      end

      context 'when provided' do
        let(:opts) { { name: 'John' } }

        describe '.valid?' do
          subject { args_object }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
