# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    ContractAttribute = Struct.new(:name, :type, :default)

    # Contract class enforces attribute validation rules
    class Contract
      attr_accessor :attributes

      def initialize
        @attributes = []
      end

      # Ad an attribute contract
      #
      # @param [Symbol] name Attribute name
      # @param [Symbol] type Attribute data type
      # @param [Hash] **opts Attribute options
      # @option opts [String] :default Default value if not provided
      def attribute(name, type = :object, **opts)
        ca = ContractAttribute.new(
          name,
          type,
          opts[:default]
        )

        attributes << ca
      end

      # Apply type conversions and defaults
      #
      # Beware: There is no check if you apply a default value that is different to underlying type
      #   e.g.
      #   attribute(:search, :string, default: 123)
      #   attribute(:count , :int   , default: 'abc')
      def apply(opts)
        attributes.each do |attribute|
          opt_value = opts.send(attribute.name)

          apply_parse_int(attribute, opts, opt_value)        if attribute.type == :int
          apply_parse_symbol(attribute, opts, opt_value)     if attribute.type == :symbol

          apply_default(attribute, opts, opt_value)          if attribute.default
        end
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
    end
  end
end
