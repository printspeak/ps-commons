# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    ContractAttribute = Struct.new(:name, :type, :default, :validations)

    # Contract defines attribute type coercion, default and validation rules
    #
    # Contract vs ContractEvaluator
    #
    # ContractEvaluator - Uses the contract meta data and the command specific input parameter (aka opts)
    # to alter the opts as needed (coercion, defaults) and then apply validations and keeps the list of validation errors.
    class Contract
      attr_accessor :attributes

      def initialize
        @attributes = []
      end

      # Add an attribute contract
      #
      # @param [Symbol] name Attribute name
      # @param [Symbol] type Attribute data type
      # @param [Hash] **opts Attribute options
      # @option opts [String] :default Default value if not provided
      def attribute(name, type = :object, **opts)
        validations = opts[:validations] || []
        validations << :required if opts[:required]

        ca = ContractAttribute.new(
          name,
          type,
          opts[:default],
          validations
        )

        attributes << ca
      end

      def apply(opts)
        evaluator = Ps::Commons::ContractEvaluator.new(self)
        evaluator.evaluate(opts)
        evaluator
      end
    end
  end
end
