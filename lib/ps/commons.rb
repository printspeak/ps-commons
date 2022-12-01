# frozen_string_literal: true

require 'active_record'

require 'ps/commons/version'
require 'ps/commons/contract'
require 'ps/commons/queries/aggregate_query_builder'
require 'ps/commons/queries/query'

module Ps
  module Commons
    # raise Ps::Commons::Error, 'Sample message'
    Error = Class.new(StandardError)

    # Your code goes here...
  end
end
