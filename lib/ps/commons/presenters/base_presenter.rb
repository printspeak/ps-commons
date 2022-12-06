# frozen_string_literal: true

module Ps
  module Commons
    # Use presenters when you want to shape data for a specific view.
    #
    # You can specify your outputs and then will be set on the output data object.
    # You implement the call method to set your outputs.
    # If you mark an output as required, then it will raise an error if it is not set in your call method.
    class BasePresenter
      attr_reader :opts
      attr_accessor :contract

      def call
        raise NoMethodError, 'implement the call method in your presenter object'
      end

      # You can use Kernel#caller
      # puts caller

      # Or if you want to remove bin/bundle, lib/ruby/gems/* etc from the stack.
      # you can can filter for unique application path entry or other exclusions as needed.

      def call_stack(app_path_identifier)
        # some filter that is unique to your application path, add exclusions as needed
        stack = caller.select { |i| i.include?(app_path_identifier) }

        # example stack item: /Users/xmen/dev/my_company/my_app/app/presenters/base_presenter.rb:90:in `block (2 levels) in outputs'"
        # callee            : base_presenter.rb:90
        puts caller
        {
          callee: stack.first.split('/').last.split(':')[0, 2].join(':'),
          stack: stack
        }
      end

      def around_call
        # puts 'defined method around_call - before super' # if self.class.to_s != "FakePresenter"
        validate_inputs
        call
        # puts 'defined method around_call - after super' # if self.class.to_s != "FakePresenter"
        validate_outputs
        # puts 'defined method around_call - after validate_outputs' # if self.class.to_s != "FakePresenter"
        OpenStruct.new(@outputs)
      end

      private

      def validate_outputs
        @required_outputs.each do |output|
          raise ArgumentError, "#{self.class} missing required output '#{output}'" if @outputs[output].nil?
        end
      end

      def validate_inputs
        contract&.apply(opts)
      end

      # Initialize a presenter using positional and/or keyword arguments
      #
      # If you use positional args, you would define an initialize method in your presenter to handle them.
      # If you use keyword args, you would define a contract in your presenter to handle them.
      def initialize(*_args, **opts)
        # puts 'defined method initialize' # if subclass.to_s != "FakePresenter"

        @contract = self.class.contract
        @opts = OpenStruct.new(opts)

        # puts '@outputs - before'
        @outputs = {}
        # puts @outputs
        # puts '@outputs - after'
        @required_outputs = if self.class.superclass.respond_to?(:required_outputs)
                              self.class.superclass.required_outputs | self.class.required_outputs
                            else
                              self.class.required_outputs
                            end

        # puts "defined method initialize - before super" # if subclass.to_s != "FakePresenter"
        # super(*args, **opts)
        # puts "defined method initialize - after super" # if subclass.to_s != "FakePresenter"

        # rescue
      rescue StandardError
        call_stack('printspeak/printspeak-master')
      end

      class << self
        def present(*args, **opts)
          # we have been using custom initializers that do not conform to the **opts, this is a backwards compatibility workaround
          # if opts.empty?
          #   new(*args).around_call
          # else
          #   new(*args, **opts).around_call
          # end
          new(*args, **opts).around_call
        end

        def contract(&block)
          return @contract if defined? @contract

          @contract = Ps::Commons::Contract.new
          @contract.instance_eval(&block) if block_given?
          @contract
        end
        alias options contract

        def outputs(*outputs, required: false)
          outputs.each do |output|
            define_method(output) do
              @outputs[output]
            end
            define_method("#{output}=") do |value|
              puts JSON.pretty_generate(call_stack('printspeak/printspeak-master')) unless @outputs
              @outputs[output] = value
            end
          end
          required_outputs.concat(outputs) if required
        end

        def required_outputs
          @required_outputs ||= []
        end
      end
    end
  end
end
