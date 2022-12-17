# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    ContractAttribute = Struct.new(:name, :type, :default, :validations)

    # Contract evaluator class enforces attribute validation rules
    #
    # Contract vs ContractEvaluator
    #
    # Contract - Holds contract meta data.  eg. attributes with type, default and validation rules.
    # ContractEvaluator - Uses the contract meta data and the command specific input parameter (aka opts)
    # to alter the opts as needed (coercion, defaults) and then apply validations and keeps the list of validation errors.
    class ContractEvaluator
      attr_accessor :contract
      attr_accessor :errors

      def initialize(contract)
        @contract = contract
        @errors = []
      end

      # Evaluate type coercion, defaults and validations against the given opts
      #
      # Beware: There is no check if you apply a default value that is different to underlying type
      #   e.g.
      #   attribute(:search, :string, default: 123)
      #   attribute(:count , :int   , default: 'abc')
      def evaluate(opts)
        @errors = []

        contract.attributes.each do |attribute|
          opt_value = opts.send(attribute.name)

          apply_parse_int(attribute, opts, opt_value)         if attribute.type == :int
          apply_parse_symbol(attribute, opts, opt_value)      if attribute.type == :symbol

          apply_default(attribute, opts, opt_value)           if attribute.default
          apply_validations(attribute, opt_value)             if attribute.validations.present?
        end
      end

      def valid?
        errors.empty?
      end

      private

      def apply_default(attribute, opts, opt_value)
        return if opt_value

        opts.send("#{attribute.name}=", attribute.default)
      end

      def apply_parse_int(attribute, opts, opt_value)
        return unless opt_value

        opts.send("#{attribute.name}=", Integer(opt_value, exception: false))
      end

      def apply_parse_symbol(attribute, opts, opt_value)
        return unless opt_value

        opts.send("#{attribute.name}=", opt_value.to_s.to_sym)
      end

      # Currently only supports :required validation, but can be extended to
      # support more validations such as :min_length, :max_length, -> (value) { !value.blank? }, etc.
      def apply_validations(attribute, opt_value)
        attribute.validations.each do |validation|
          validate_required(attribute, opt_value) if validation == :required
        end
      end

      def validate_required(attribute, opt_value)
        return if opt_value

        errors << "#{attribute.name} is required"
      end
    end
  end
end
