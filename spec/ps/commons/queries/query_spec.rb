# frozen_string_literal: true

class SomeTable < ::ActiveRecord::Base
  establish_connection(adapter: 'sqlite3', database: ':memory:')

  connection.create_table :some_tables do |t|
    t.string :name
  end
end

class AnotherTable < ::ActiveRecord::Base
  establish_connection(adapter: 'sqlite3', database: ':memory:')

  connection.create_table :another_tables do |t|
    t.string :name
  end

  default_scope { order('another_table.some_created_at DESC NULLS LAST') }
end

class MissingCallMethodQuery < Ps::Commons::Query
  default_scope :some_table
end

class NoScopeQuery < Ps::Commons::Query
  def call
  end
end

class SymbolDrivenQuery < NoScopeQuery
  default_scope :some_table
end

class LambdaDrivenQuery < NoScopeQuery
  default_scope { SomeTable.where.not(os: nil) }
end

RSpec.describe Ps::Commons::Query do
  let(:params) { {} }
  let(:scope) { nil }

  describe '#query' do
    subject { run_query }

    context 'when misconfigured' do
      context 'with missing call method' do
        let(:run_query) { MissingCallMethodQuery.query_as_scope(**params) }

        it { expect { subject }.to raise_error NoMethodError, 'implement the call method in your query object' }
      end

      context 'with no scope provided' do
        let(:run_query) { NoScopeQuery.query_as_scope(**params) }

        it { expect { subject }.to raise_error ArgumentError, 'scope is required' }
      end
    end

    context 'when configured with valid scope' do
      subject { run_query.to_sql.squeeze(' ') }

      context 'with scope passed in via query' do
        context 'when standard default scope' do
          let(:run_query) { NoScopeQuery.query_as_scope(SomeTable.all, **params) }

          it { is_expected.to eq('SELECT "some_tables".* FROM "some_tables"') }
        end

        context 'when modified default scope' do
          let(:run_query) { NoScopeQuery.query_as_scope(AnotherTable.all, **params) }

          it { is_expected.to eq('SELECT "another_tables".* FROM "another_tables" ORDER BY another_table.some_created_at DESC NULLS LAST') }
        end
      end

      context 'with default_scope' do
        context 'when using :symbol (model name)' do
          let(:run_query) { SymbolDrivenQuery.query_as_scope(**params) }

          it { is_expected.to eq('SELECT "some_tables".* FROM "some_tables"') }
        end

        context 'when using lambda' do
          let(:run_query) { LambdaDrivenQuery.query_as_scope(**params) }

          it { is_expected.to eq('SELECT "some_tables".* FROM "some_tables" WHERE ("some_tables"."os" IS NOT NULL)') }
        end
      end
    end
  end

  describe '#clean_sort_direction' do
    subject { described_class.new(ActiveRecord).clean_sort_direction(direction) }

    context 'when direction is nil' do
      let(:direction) { nil }

      it { is_expected.to eq('') }
    end

    context "when direction is ''" do
      let(:direction) { '' }

      it { is_expected.to eq('') }
    end

    context 'when direction is valid' do
      context "when direction is 'asc'" do
        let(:direction) { 'asc' }

        it { is_expected.to eq('ASC') }
      end

      context "when direction is 'desc'" do
        let(:direction) { 'desc' }

        it { is_expected.to eq('DESC') }
      end

      context 'when direction is :asc' do
        let(:direction) { :asc }

        it { is_expected.to eq('ASC') }
      end

      context 'when direction is :desc' do
        let(:direction) { :desc }

        it { is_expected.to eq('DESC') }
      end
    end

    context 'when direction is invalid' do
      let(:direction) { 'invalid' }

      it { is_expected.to eq('') }
    end
  end
end
