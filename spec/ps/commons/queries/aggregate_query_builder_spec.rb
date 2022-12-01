# frozen_string_literal: true

class Address < ::ActiveRecord::Base
  establish_connection(adapter: 'sqlite3', database: ':memory:')

  connection.create_table :addresses do |t|
    t.string :name
  end
end

RSpec.describe Ps::Commons::AggregateQueryBuilder do
  let(:instance) { described_class.new(connection: Address.connection) }

  describe '#initialize' do
    it { expect(instance).to be_a(described_class) }

    describe '.queries' do
      subject { instance.queries }

      it { is_expected.to be_empty }
    end
  end

  describe '#add' do
    let(:name) { :test }
    let(:query) { Address.unscoped.all.order(:name) }
    let(:clear_order) { true }
    let(:command) { instance.add(name, query, clear_order: clear_order) }

    context 'when a named query is added to the list of queries' do
      subject { command }

      it do
        expect { subject }.to change { instance.queries.count }.by(1)
      end
    end

    describe '.queries' do
      subject { instance.queries.first }

      before { command }

      it 'adds a named query and removes any order clauses' do
        expect(subject).to have_attributes(
          name: name,
          raw_sql: "SELECT 'test' as agg_name, count(*) as agg_count FROM \"addresses\""
        )
      end

      context 'when clear_order is false' do
        let(:clear_order) { false }

        it do
          expect(subject).to have_attributes(
            name: name,
            raw_sql: "SELECT 'test' as agg_name, count(*) as agg_count FROM \"addresses\" ORDER BY \"addresses\".\"name\" ASC"
          )
        end
      end
    end

    describe '#build_aggregated_query' do
      subject { instance.build_aggregated_query }

      before { command }

      let(:name) { :test }
      let(:query) { Address.unscoped.all.order(:name) }
      let(:clear_order) { true }
      let(:command) { instance.add(name, query, clear_order: clear_order) }

      it do
        expect(subject).to eq(
          "SELECT agg_name, agg_count FROM (\n  SELECT 'test' as agg_name, count(*) as agg_count FROM \"addresses\"\n) as counts"
        )
      end
    end

    describe '#execute_query' do
      subject { instance.execute_query }

      before { command }

      let(:name) { :test }
      let(:query) { Address.unscoped.all.order(:name) }
      let(:command) { instance.add(name, query) }

      it { is_expected.to eq({ test: 0 }) }
    end
  end
end
