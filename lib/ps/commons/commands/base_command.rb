# frozen_string_literal: true

module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    # Use commands (or interactors) for any database or process action
    #
    # Commands are used to encapsulate the logic of a single action. They are
    # great for create, update and delete actions. They are also good for single
    # responsibility actions like sending an email or processing an API request.
    #
    # How to work with validation and errors in commands.
    #
    # You have two areas to play with.
    #
    # 1. The args contract (Ps::Commons::Args) which stores input arguments with type coercion,
    #    default values and validation.
    # 2. The command object itself which can have its own validations and errors.
    #
    # class MyCommand < Ps::Commons::BaseCommand
    #   attr_reader :output
    #
    #   args do
    #     attribute :name, :string
    #     attribute :age, :integer
    #     attribute :type, :string, default: 'user'
    #
    #     validates :type, inclusion: { in: %w(user admin) }
    #   end
    #
    #   def call
    #     return unless args.valid?
    #
    #     errors.add(:base, 'None shall pass') if args.name == 'Gandalf'
    #
    #     if valid?
    #       @output = "Hello #{args.type} #{args.name}"
    #     end
    #   end

    # command1 = MyCommand.run(name: 'David', age: 33)
    # command1.output # => 'Hello user David'
    #
    # command2 = MyCommand.run(name: 'Gandalf', age: 1000)
    # command2.valid? # => false
    # command2.errors.full_messages # => ['None shall pass']
    # command2.output # => nil
    #
    # command3 = MyCommand.run(name: 'David', age: 33, type: 'cool-cat')
    # command3.valid? # => false
    # command3.errors.full_messages # => ['Type is not included in the list']
    # command3.output # => nil
    #
    # command4 = MyCommand.run(name: 'David', age: 33, type: 'admin')
    # command4.valid? # => true
    # command4.output # => 'Hello admin David'
    class BaseCommand
      include Ps::Commons::AttachArgs
      include ActiveModel::Validations

      def initialize(**opts)
        @args = self.class.args.new(**opts)
      end

      def call
        raise NoMethodError, 'implement the call method in your command object'
      end

      def around_call
        args.valid?
        call
        valid?
      end

      def success?
        valid? && args.valid?
      end

      def failure?
        !success?
      end

      def error_messages(type = :command)
        messages = []
        messages << args.errors.full_messages if %i[args all].include?(type)
        messages << errors.full_messages if %i[command all].include?(type)
        messages.flatten
      end

      class << self
        attr_reader :after_contract_validation

        def run(**opts)
          new(**opts).tap(&:around_call)
        end

        def model_name
          ActiveModel::Name.new(self, nil, 'NotSet')
        end
      end
    end
  end
end
