# frozen_string_literal: true

module Ps
  module Commons
    require 'active_support/core_ext/module/remove_method'
    require 'active_support/core_ext/array/extract_options'

    class Class
      # Declare a class-level attribute whose value is inheritable by subclasses.
      # Subclasses can change their own value and it will not impact parent class.
      #
      #   class Base
      #     class_attribute :setting
      #   end
      #
      #   class Subclass < Base
      #   end
      #
      #   Base.setting = true
      #   Subclass.setting            # => true
      #   Subclass.setting = false
      #   Subclass.setting            # => false
      #   Base.setting                # => true
      #
      # In the above case as long as Subclass does not assign a value to setting
      # by performing <tt>Subclass.setting = _something_ </tt>, <tt>Subclass.setting</tt>
      # would read value assigned to parent class. Once Subclass assigns a value then
      # the value assigned by Subclass would be returned.
      #
      # This matches normal Ruby method inheritance: think of writing an attribute
      # on a subclass as overriding the reader method. However, you need to be aware
      # when using +class_attribute+ with mutable structures as +Array+ or +Hash+.
      # In such cases, you don't want to do changes in places but use setters:
      #
      #   Base.setting = []
      #   Base.setting                # => []
      #   Subclass.setting            # => []
      #
      #   # Appending in child changes both parent and child because it is the same object:
      #   Subclass.setting << :foo
      #   Base.setting               # => [:foo]
      #   Subclass.setting           # => [:foo]
      #
      #   # Use setters to not propagate changes:
      #   Base.setting = []
      #   Subclass.setting += [:foo]
      #   Base.setting               # => []
      #   Subclass.setting           # => [:foo]
      #
      # For convenience, a query method is defined as well:
      #
      #   Subclass.setting?       # => false
      #
      # Instances may overwrite the class value in the same way:
      #
      #   Base.setting = true
      #   object = Base.new
      #   object.setting          # => true
      #   object.setting = false
      #   object.setting          # => false
      #   Base.setting            # => true
      #
      # To opt out of the instance reader method, pass :instance_reader => false.
      #
      #   object.setting          # => NoMethodError
      #   object.setting?         # => NoMethodError
      #
      # To opt out of the instance writer method, pass :instance_writer => false.
      #
      #   object.setting = false  # => NoMethodError
      def class_attribute(*attrs)
        options = attrs.extract_options!
        instance_reader = options.fetch(:instance_reader, true)
        instance_writer = options.fetch(:instance_writer, true)

        attrs.each do |name|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{name}() nil end
            def self.#{name}?() !!#{name} end

            def self.#{name}=(val)
              singleton_class.class_eval do
                remove_possible_method(:#{name})
                define_method(:#{name}) { val }
              end

              if singleton_class?
                class_eval do
                  remove_possible_method(:#{name})
                  def #{name}
                    defined?(@#{name}) ? @#{name} : singleton_class.#{name}
                  end
                end
              end
              val
            end

            if instance_reader
              remove_possible_method :#{name}
              def #{name}
                defined?(@#{name}) ? @#{name} : self.class.#{name}
              end

              def #{name}?
                !!#{name}
              end
            end
          RUBY

          attr_writer name if instance_writer
        end
      end

      private
      def singleton_class?
        ancestors.first != self
      end
    end

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
        puts 'defined method around_call - before super' # if self.class.to_s != "FakePresenter"
        validate_inputs
        call
        puts 'defined method around_call - after super' # if self.class.to_s != "FakePresenter"
        validate_outputs
        puts 'defined method around_call - after validate_outputs' # if self.class.to_s != "FakePresenter"
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
        puts 'defined method initialize' # if subclass.to_s != "FakePresenter"

        @contract = self.class.contract
        @opts = OpenStruct.new(opts)

        puts '@outputs - before'
        @outputs = {}
        puts @outputs
        puts '@outputs - after'
        @required_outputs = self.class.required_outputs

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

        # def inherited(subclass)
        # interceptor = const_set("#{subclass.name.split('::').last}Interceptor", Module.new)
        # if subclass.to_s.include?("Fake")
        #   # puts "subclass: #{subclass}"
        #   # puts "interceptor: #{interceptor}"
        # end
        # interceptor.define_method(:call) do
        #   puts "defined method call - before super" if subclass.to_s != "FakePresenter"
        #   validate_inputs
        #   super()
        #   puts "defined method call - after super" if subclass.to_s != "FakePresenter"
        #   validate_outputs
        #   puts "defined method call - after validate_outputs" if subclass.to_s != "FakePresenter"
        #   OpenStruct.new(@outputs)
        # end
        # interceptor.define_method(:initialize) do |*args, **opts|
        #   puts "defined method initialize" if subclass.to_s != "FakePresenter"
        #   @contract = self.class.contract
        #   @opts  = OpenStruct.new(opts)

        #   @opts  = OpenStruct.new(**opts)

        #   @outputs = {}
        #   @required_outputs = subclass.required_outputs

        #   puts "defined method initialize - before super" if subclass.to_s != "FakePresenter"
        #   super(*args)
        #   puts "defined method initialize - after super" if subclass.to_s != "FakePresenter"
        # end
        # subclass.prepend(interceptor)
        # end
      end
    end
  end
end
