# frozen_string_literal: true

RSpec.describe Ps::Commons::Contract do
  let(:instance) { described_class.new }

  shared_context :with_attributes do
    before do
      instance.attribute(:search, :string)
      instance.attribute(:some_object)
      instance.attribute(:count, :int, default: 0)
      instance.attribute(:order, :symbol, default: :asc)
    end
  end

  describe '#initialize' do
    it do
      is_expected
        .to be_a(described_class)
        .and have_attributes(attributes: [])
    end
  end

  describe '#attribute' do
    include_context :with_attributes

    subject { instance.attributes }

    it do
      is_expected
        .to include(
          Ps::Commons::ContractAttribute.new(:search, :string, nil),
          Ps::Commons::ContractAttribute.new(:some_object, :object, nil),
          Ps::Commons::ContractAttribute.new(:count, :int, 0),
          Ps::Commons::ContractAttribute.new(:order, :symbol, :asc)
        )
    end
  end

  describe '#apply' do
    include_context :with_attributes

    subject { opts }

    before { instance.apply(opts) }

    context 'when opts are not provided -> apply defaults' do
      let(:opts) { OpenStruct.new }

      it do
        is_expected.to have_attributes(count: 0, order: :asc)
        # nil values are not converted to defaults
        # this could be an issue that needs to be addressed
        is_expected.not_to respond_to(:search)
        is_expected.not_to respond_to(:some_object)
      end
    end

    context 'when opts have valid values' do
      let(:opts) do
        OpenStruct.new(
          search: 'abc',
          some_object: {},
          count: 123,
          order: 'desc'
        )
      end

      it do
        is_expected.to have_attributes(
          search: 'abc',
          some_object: {},
          count: 123,
          order: :desc
        )
      end
    end

    context 'when opts need type conversion' do
      # Currently supports int and symbol, add more as needed
      let(:opts) do
        OpenStruct.new(
          count: '123',
          order: 'desc'
        )
      end

      it do
        is_expected.to have_attributes(
          count: 123,
          order: :desc
        )
      end
    end
  end
end
