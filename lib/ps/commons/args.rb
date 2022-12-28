# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    # Args is an in memory model for passing arguments to queries, presenters and commands.
    #
    # It uses ActiveModel under the hood and so will feel familiar to Rails developers.
    #
    # Of course, you can use active model validations, attributes, initializer assignment, callbacks, etc directly
    # on your query, presenter or command classes. But this way there is a clear separation of concerns, providing
    # composition over inheritance.
    #
    # For example:
    # A class like a presenter has both inputs and outputs, and if you use ActiveModel directly, you would have no
    # clear way to separate the two. But with Args, you can define separate contracts for inputs and outputs.
    class Args
      # include ActiveModel::API
      # extend ActiveSupport::Concern
      # Introduce Rails 5 attribute methods
      include ActiveModel::Attributes

      # Accept constructor arguments as a hash and assign them to writable accessors (attr_accessor, attr_writer or attribute)
      include ActiveModel::AttributeAssignment

      # Add standard ActiveModel validations
      include ActiveModel::Validations

      # Add JSON serialization
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
      end
    end
  end
end
