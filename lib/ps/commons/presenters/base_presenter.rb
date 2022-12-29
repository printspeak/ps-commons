# frozen_string_literal: true

module Ps
  module Commons
    # Use presenters when you want to shape data for a specific view.
    #
    # You can specify your outputs and then will be set on the output data object.
    # You implement the call method to set your outputs.
    # If you mark an output as required, then it will raise an error if it is not set in your call method.
    class BasePresenter
      include Ps::Commons::AttachArgs

      # backward compatibility, if you encounter opts, convert to args
      def opts
        args
      end

      # Define the outputs for the presenter
      attr_accessor :output_contract

      def call
        raise NoMethodError, 'implement the call method in your presenter object'
      end

      # Initialize a presenter using positional and/or keyword arguments
      #
      # If you use positional args, you would define an initialize method in your presenter to handle them.
      # If you use keyword args, you would define a contract in your presenter to handle them.
      def initialize(*_args, **opts)
        @args = self.class.args.new(**opts)
        @output_contract = extract_output_contract
        @outputs = default_outputs
      end

      def around_call
        # just ensuring that the args are valid, but still allows call where you can interrogate the args
        args.valid?
        call
        validate_outputs

        OpenStruct.new(@outputs)
      end

      private

      def validate_outputs
        required_outputs.each do |output|
          raise ArgumentError, "#{self.class} missing required output '#{output}'" if @outputs[output].nil?
        end
      end

      def required_outputs
        @required_outputs ||= output_contract.select { |_name, definition| definition[:required] }.keys
      end

      # Extract the output definitions from the class hierarchy
      def extract_output_contract
        self.class.ancestors
            .select { |klass| klass.method_defined?(:output_contract) }
            .reverse
            .map(&:output_contract)
            .reduce({}, :merge)
      end

      def default_outputs
        output_contract.each_with_object({}) do |(name, _definition), hash|
          hash[name] = nil # definition[:default]
        end
      end

      class << self
        def present(*args, **opts)
          new(*args, **opts).around_call
        end

        def contract(&block)
          args(&block)
        end

        def outputs(*outputs, required: false)
          outputs.each do |output|
            define_method(output) do
              @outputs[output]
            end
            define_method("#{output}=") do |value|
              @outputs[output] = value
            end
            add_output_contract(output, required)
          end
        end

        def add_output_contract(name, required)
          output_contract[name] = {
            name: name,
            required: required
          }
        end

        def output_contract
          @output_contract ||= {}
        end
      end
    end
  end
end
