# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/dos_time'

describe 'Archive::Zip::DOSTime#cmp' do
  it 'raises an exception if other is not a Zip::DOSTime' do
    dos_time = Archive::Zip::DOSTime.new
    other = nil
    _(->{ dos_time.cmp(other) }).must_raise ArgumentError
  end

  it 'returns 1 when other is earlier' do
    dos_time = Archive::Zip::DOSTime.new(Time.utc(2000))
    other = Archive::Zip::DOSTime.new(Time.utc(1990))
    _(dos_time.cmp(other)).must_equal 1
  end

  it 'returns -1 when other is later' do
    dos_time = Archive::Zip::DOSTime.new(Time.utc(2000))
    other = Archive::Zip::DOSTime.new(Time.utc(2010))
    _(dos_time.cmp(other)).must_equal(-1)
  end

  it 'returns 0 when other is the same' do
    dos_time = Archive::Zip::DOSTime.new(Time.utc(2000))
    other = Archive::Zip::DOSTime.new(Time.utc(2000))
    _(dos_time.cmp(other)).must_equal 0
  end
end

describe 'Archive::Zip::DOSTime#<=>' do
  it 'is an alias of #cmp' do
    dos_time = Archive::Zip::DOSTime.new
    _(dos_time.method(:<=>)).must_equal dos_time.method(:cmp)
  end
end
