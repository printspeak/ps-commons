# frozen_string_literal: true

RSpec.describe Ps::Commons do
  it 'has a version number' do
    expect(Ps::Commons::VERSION).not_to be_nil
  end

  it 'has a standard error' do
    expect { raise Ps::Commons::Error, 'some message' }
      .to raise_error('some message')
  end
end
