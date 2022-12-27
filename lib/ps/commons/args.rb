# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    # Args is a base class for query, presenter and command specific input parameters
    #
    # It uses ActiveModel under the hood and so will feel familiar to Rails developers.
    class Args
      # include ActiveModel::API
      # extend ActiveSupport::Concern
      include ActiveModel::Attributes
      include ActiveModel::AttributeAssignment
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      # include ActiveModel::Conversion

      # included do
      #   extend ActiveModel::Naming
      #   extend ActiveModel::Translation
      # end

      def initialize(attributes = {})
        super()

        assign_attributes(attributes) if attributes
      end

      # Used by ActiveModel::Serializers::JSON
      def attributes
        instance_values
      end

      class << self
        def define_class(name = 'NotSet', &block)
          klass = Class.new(Ps::Commons::Args)

          klass.define_singleton_method(:model_name) do
            ActiveModel::Name.new(self, nil, name)
          end

          klass.class_eval(&block)

          klass
        end

        def create(arg_class, **opts)
          arg_class.new(**opts)
        end
      end
    end
  end
end
