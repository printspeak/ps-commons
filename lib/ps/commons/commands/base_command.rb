# frozen_string_literal: true

module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    # Use commands (or interactors) for any database or process action
    #
    # Commands are used to encapsulate the logic of a single action. They are
    # great for create, update and delete actions. They are also good for single
    # responsibility actions like sending an email or processing an API request.
    class BaseCommand
      attr_reader :opts
      attr_accessor :contract
      attr_reader :contract_evaluator
      attr_accessor :success

      def initialize(**opts)
        @contract = self.class.contract
        @contract_evaluator = nil
        @opts = OpenStruct.new(opts)
        @success = false
      end

      def call
        raise NoMethodError, 'implement the call method in your command object'
      end

      def around_call
        @contract_evaluator = contract.apply(opts)
        call if valid?
      end

      def valid?
        contract_evaluator.valid?
      end

      def validation_errors
        contract_evaluator.errors
      end

      # Is the command successful?
      #
      # Example:
      # def call
      #   some = SomeModel.create(name: 'John')
      #   self.success = some.save
      # end
      #
      # @return [Boolean]
      def successful?
        success == true
      end

      class << self
        def run(**opts)
          new(**opts).tap(&:around_call)
        end

        def contract(&block)
          return @contract if defined? @contract

          @contract = Ps::Commons::Contract.new
          @contract.instance_eval(&block) if block_given?
          @contract
        end
      end
    end
  end
end
