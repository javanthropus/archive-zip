# encoding: UTF-8

require 'minitest/autorun'
require 'stringio'

require 'archive/support/ioextensions.rb'

describe 'IOExtensions.read_exactly' do
  it 'reads and returns length bytes from a given IO object' do
    io = StringIO.new('This is test data')
    IOExtensions.read_exactly(io, 4).must_equal 'This'
    IOExtensions.read_exactly(io, 13).must_equal ' is test data'
  end

  it 'raises an error when too little data is available' do
    io = StringIO.new('This is test data')
    lambda do
      IOExtensions.read_exactly(io, 18)
    end.must_raise EOFError
  end

  it 'can read 0 bytes' do
    io = StringIO.new('This is test data')
    IOExtensions.read_exactly(io, 0).must_equal ''
  end
end
