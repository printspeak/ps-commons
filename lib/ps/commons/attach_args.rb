# frozen_string_literal: true

# NOTE: Should this class be renamed to ArgsContract or some other name to be more specific and description?
module Ps
  # Common module contains base classes and modules used by Printspeak
  module Commons
    # When you want to make arguments available to a class, you can use `include Ps::Commons::AttachArgs` and
    # now you will have both the class level definition of the arguments and the instance level access to the
    # incoming arguments.
    #
    # For example:
    # class BaseQuery
    #   include Ps::Commons::AttachArgs
    # end
    #
    # class MyQuery < BaseQuery
    #   args do
    #     attribute :name, :string
    #     attribute :age, :integer
    #     attribute :type, :string, default: 'user'
    #   end
    # end
    #
    # query = MyQuery.new(name: 'David', age: 33)
    # query.args.name # => 'David'
    # query.args.age # => 33
    # query.args.type # => 'user'
    module AttachArgs
      attr_reader :args

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # Build the args meta class while accepting a block to define the attributes, validations, etc.
      module ClassMethods
        def args(model_name = 'NotSet', &block)
          @args ||= Ps::Commons::Args.define_class(model_name, &block)
        end
      end
    end
  end
end
