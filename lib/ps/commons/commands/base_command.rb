# frozen_string_literal: true

module Ps
  module Commons
    # Use commands (or interactors) for any database or process action
    #
    # Commands are used to encapsulate the logic of a single action. They are
    # great for create, update and delete actions. They are also good for single
    # responsibility actions like sending an email or processing an API request.
    class BaseCommand
      attr_reader :opts
      attr_accessor :contract

      class << self
        # Run the command
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

      def initialize(**opts)
        @contract = self.class.contract
        @opts = OpenStruct.new(opts)
      end

      def call
        raise NoMethodError, 'implement the call method in your command object'
      end

      def around_call
        contract&.apply(opts)
        call
      end
    end
  end
end
