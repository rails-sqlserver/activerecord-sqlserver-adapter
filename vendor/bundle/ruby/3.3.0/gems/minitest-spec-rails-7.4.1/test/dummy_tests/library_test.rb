require 'test_helper_dummy'
require "#{Dummy::Application.root}/lib/library"

class LibraryTest < ActiveSupport::TestCase
  it 'reflects' do
    expect(described_class).must_equal Library
  end
end

describe Library do
  it 'reflects' do
    expect(described_class).must_equal Library
    expect(self.class.described_class).must_equal Library
  end
end
