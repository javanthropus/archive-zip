# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/dos_time'

describe 'Archive::Zip::DOSTime#to_time' do
  let(:epoc) { 0b0000000_0001_00001_00000_000000_00000 }
  let(:end_times) { 0b1110111_1100_11111_10111_111011_11101 }

  it 'returns an equivalent instance of Time' do
    _(Archive::Zip::DOSTime.new(epoc).to_time).must_equal Time.local(1980, 1, 1, 0, 0, 0)
    _(Archive::Zip::DOSTime.new(end_times).to_time).must_equal Time.local(2099, 12, 31, 23, 59, 58)
  end
end
