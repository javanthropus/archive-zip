# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/dos_time'

describe 'Archive::Zip::DOSTime#to_i' do
  let(:epoc) { 0b0000000_0001_00001_00000_000000_00000 }
  let(:end_times) { 0b1110111_1100_11111_10111_111011_11101 }

  it 'returns the time structure encoded as an integer' do
    _(Archive::Zip::DOSTime.new(epoc).to_i).must_equal epoc
    _(Archive::Zip::DOSTime.new(end_times).to_i).must_equal end_times
  end
end
