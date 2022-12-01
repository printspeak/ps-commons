# frozen_string_literal: true

module Ps
  module Commons
    # Aggregate query builder will UNION multiple queries together to build a set of key/values,
    # where the key is the name of the aggregate and value is the count associated with the query.
    #
    # In future this may support other SQL aggregate functions such as SUM, MIN, MAX, AVG
    class AggregateQueryBuilder
      AggregateQuery = Struct.new(:name, :raw_sql)

      attr_accessor :queries
      attr_accessor :connection

      def initialize(connection: ActiveRecord::Base.connection)
        @queries = []
        @connection = connection
      end

      # Add a named / query to the list of queries.
      #
      # @param [TRUE/FALSE] clear_order should the trailing ORDER BY be removed from the query, defaults to true
      def add(name, query, clear_order: true)
        count_query = query.clone
        count_query.reorder!('') if clear_order
        count_query = count_query.select("'#{name}' as agg_name, count(*) as agg_count")

        raw_sql = count_query.to_sql

        @queries << AggregateQuery.new(name, raw_sql.squeeze(' '))
      end

      # Add a named / raw sql to the list of queries.
      #
      # This is useful if you want fine control over the SQL you need to execute
      def add_sql(name, raw_sql)
        @queries << AggregateQuery.new(name, raw_sql)
      end

      def build_aggregated_query
        raw_sql_list = queries.map { |q| q.raw_sql.split("\n").map { |line| "  #{line}" }.join("\n") }
        query = raw_sql_list.join("\n\n  UNION ALL\n\n")
        "SELECT agg_name, agg_count FROM (\n#{query}\n) as counts"
      end

      alias to_sql build_aggregated_query

      # Run the query and return a hash of key/values.
      #
      # Example from order_index query.
      # {
      #   :wip_all=>"52",
      #   :wip=>"50",
      #   :wip_completed=>"2",
      #   :overdue=>"50",
      #   :due_today=>"0",
      #   :due_tomorrow=>"0",
      #   :due_eom=>"50",
      #   :my_bookmarks=>"1",
      #   :show_hidden=>"0",
      #   :orders_first=>"4",
      #   :orders_web=>"2",
      #   :orders_hold=>"0",
      #   :orders_no_due=>"0",
      #   :orders_approved=>"0",
      #   :orders_pending=>"0",
      #   :orders_canceled=>"2"
      # }
      def execute_query
        sql = build_aggregated_query
        result = connection.execute(sql)

        result.each_with_object({}) do |row, obj|
          obj[row['agg_name'].to_sym] = row['agg_count'].to_i
        end
      end

      def debug(format_sql: false)
        queries.each do |query|
          puts '-' * 80
          puts "- #{query.name}"
          puts '-' * 80
          sql = format_sql ? Queries::Base::Query.format_sql(query.raw_sql) : query.raw_sql
          puts sql
        end
        nil
      end
    end
  end
end
