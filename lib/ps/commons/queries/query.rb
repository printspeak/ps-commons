# frozen_string_literal: true

module Ps
  module Commons
    # Base class for query objects
    #
    # Use Query to provide complex query expressions using single responsibility principal.
    #
    # References:
    #
    # https://craftingruby.com/posts/2015/06/29/query-objects-through-scopes.html
    # https://mkdev.me/en/posts/how-to-use-query-objects-to-refactor-rails-sql-queries
    # https://github.com/RichOrElse/query_delegator
    class Query
      include Ps::Commons::AttachArgs

      attr_accessor :scope

      # backward compatibility, if you encounter opts, convert to args
      def opts
        args
      end

      class << self
        # Run the query and return the query instance
        #
        # Use this technique when the query is producing more that one scope
        def query(scope = nil, **opts)
          new(scope, **opts).tap(&:call)
        end

        # Run the query and return an ActiveRecord scope
        #
        # Use this technique when the query is producing a single scope
        def query_as_scope(scope = nil, **opts)
          query(scope, **opts).scope
        end

        def scope
          return @scope if defined? @scope

          @scope = nil
        end

        def default_scope(name = nil)
          @scope = if name.nil?
                     yield if block_given?
                   else
                     begin
                       name.to_s.classify.constantize.all
                     rescue StandardError
                       nil
                     end
                   end
        end

        # backward compatibility, if you encounter contract, convert to args
        def contract(&block)
          args(&block)
        end
      end

      def initialize(scope, **opts)
        @scope = scope || self.class.scope
        @args = self.class.args.new(**opts)
        raise ArgumentError, 'scope is required' if @scope.nil?
      end

      def call
        raise NoMethodError, 'implement the call method in your query object'
      end

      def validate
        contract.apply(opts)
      end

      # HELPERS

      # Helper for doing left out joins that works in both Rails4 and 5
      def left_outer_joins(lhs_table_name_plural, rhs_table_name_plural)
        if Rails::VERSION::MAJOR == 4
          foreign_key = "#{rhs_table_name_plural.to_s.singularize}_id"
          # KEEP
          # self.scope = scope.joins("LEFT OUTER JOIN #{rhs_table_name_plural} ON #{lhs_table_name_plural}.#{foreign_key} = #{rhs_table_name_plural}.id")
          # JUST TESTING WITH THIS
          self.scope = scope.joins("LEFT OUTER JOIN #{rhs_table_name_plural} ON #{rhs_table_name_plural}.id = #{lhs_table_name_plural}.#{foreign_key}")
        else
          self.scope = scope.left_outer_joins(target_table_name_plural)
        end

        scope
      end

      def clean_sort_direction(direction)
        return '' if direction.nil? || %w[asc desc].none?(direction.to_s.downcase)

        direction.to_s.upcase
      end

      def paginate
        self.scope = scope.page(opts.page).per(opts.page_size)
      end

      # Helper to building multiple aggregates (AKA Count, Sum, MIN, MAX) in a single query
      def aggregate_queries
        @aggregate_queries ||= AggregateQueryBuilder.new
      end

      # These debug helpers get used when comparing SQL from an old controller to the new sql in a query class.
      class << self
        # def log_sql(group, name, active_record)
        #   Common::Query.ab_test_query('new', group, name, active_record)
        #   # Common::Query.vscode_compare("old", "new", group, name, "psql")
        # end

        def ab_test_query(ab, group, name, active_record, **opts)
          ab_test(ab, group, name, 'psql', format_sql(active_record.to_sql), **opts)
        end

        def ab_test_sql(ab, group, name, sql, **opts)
          ab_test(ab, group, name, 'psql', format_sql(sql), **opts)
        end

        def format_sql(sql)
          sql
            .gsub(' FROM', "\nFROM")
            .gsub(' WHERE', "\nWHERE")
            .gsub(' AND', "\nAND")
            .gsub(' OR', "\nOR")
            .gsub(' ON', "\nON")
            .gsub(' GROUP BY', "\nGROUP BY")
            .gsub(' LEFT', "\nLEFT")
            .gsub(' INNER', "\nINNER")
            .gsub(/"/, '')
            .split(/\n+|\r+/)
            .map(&:strip)
            .reject(&:empty?)
            .join("\n")
            .squeeze(' ')
        end

        def ab_file(ab, group, name, ext)
          File.join(['ab', ab.to_s, group, "#{name}.#{ext}"])
        end

        def ab_test(ab, group, name, ext, content, **_opts)
          filename = ab_file(ab, group, name, ext)
          FileUtils.mkdir_p(File.dirname(filename))
          File.write(filename, content)
        end

        def vscode_compare(a, b, group, name, ext, on: :if_different)
          a_file = ab_file(a, group, name, ext)
          b_file = ab_file(b, group, name, ext)

          run_compare = on == :always || (on == :if_different && (File.exist?(a_file) && File.exist?(b_file) && File.read(a_file) != File.read(b_file)))

          return false unless run_compare

          system("code -d #{a_file} #{b_file}")
          sleep 2

          true
        end
      end
    end
  end
end
