# frozen_string_literal: true

RSpec.describe Ps::Commons::Contract do
  let(:instance) { described_class.new }

  shared_context 'with attributes' do
    before do
      instance.attribute(:search, :string)
      instance.attribute(:some_object)
      instance.attribute(:count, :int, default: 0)
      instance.attribute(:order, :symbol, default: :asc)
      instance.attribute(:name, :string, required: true)
    end
  end

  describe '#initialize' do
    it do
      expect(subject)
        .to be_a(described_class)
        .and have_attributes(attributes: [])
    end
  end

  describe '#attribute' do
    subject { instance.attributes }

    include_context 'with attributes'

    it do
      expect(subject)
        .to include(
          Ps::Commons::ContractAttribute.new(:search, :string, nil, []),
          Ps::Commons::ContractAttribute.new(:some_object, :object, nil, []),
          Ps::Commons::ContractAttribute.new(:count, :int, 0, []),
          Ps::Commons::ContractAttribute.new(:order, :symbol, :asc, []),
          Ps::Commons::ContractAttribute.new(:name, :string, nil, [:required])
        )
    end
  end

  describe '#apply' do
    subject { opts }

    include_context 'with attributes'

    before { instance.apply(opts) }

    context 'when opts are not provided -> apply defaults' do
      let(:opts) { OpenStruct.new }

      it { is_expected.to have_attributes(count: 0, order: :asc) }
      it { is_expected.not_to respond_to(:search) }
      it { is_expected.not_to respond_to(:some_object) }

      describe '#valid?' do
        subject { instance.valid? }

        it { is_expected.to be false }
      end

      describe '#errors' do
        subject { instance.errors }

        it { is_expected.to include('name is required') }
      end
    end

    context 'when opts have valid values' do
      let(:opts) do
        OpenStruct.new(
          search: 'abc',
          some_object: {},
          count: 123,
          order: 'desc',
          name: 'John'
        )
      end

      it do
        expect(subject).to have_attributes(
          search: 'abc',
          some_object: {},
          count: 123,
          order: :desc,
          name: 'John'
        )
      end

      describe '#valid?' do
        subject { instance.valid? }

        it { is_expected.to be true }
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
        expect(subject).to have_attributes(
          count: 123,
          order: :desc
        )
      end
    end
  end
end
