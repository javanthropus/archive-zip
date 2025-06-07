# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/dos_time'

describe 'Archive::Zip::DOSTime.new' do
  let(:epoc) { 0b0000000_0001_00001_00000_000000_00000 }
  let(:end_times) { 0b1110111_1100_11111_10111_111011_11101 }

  it 'uses the current time when no structure is given' do
    now = Time.now.localtime
    dos_time = Archive::Zip::DOSTime.new.to_time

    _(now.year).must_be_close_to(dos_time.year, 1)
    _(now.month).must_be_close_to(dos_time.month, 1)
    _(now.day).must_be_close_to(dos_time.day, 1)
    _(now.hour).must_be_close_to(dos_time.hour, 1)
    _(now.min).must_be_close_to(dos_time.min, 1)
    _(now.sec).must_be_close_to(dos_time.sec, 3)
  end

  it 'accepts Time instances' do
    Archive::Zip::DOSTime.new(Time.new)
  end

  it 'accepts valid Integer structures' do
    Archive::Zip::DOSTime.new(epoc)
    Archive::Zip::DOSTime.new(end_times)
  end

  it 'limits the upper bound on year to 2099' do
    dos_time = Archive::Zip::DOSTime.new(Time.utc(3000))
    _(dos_time.to_time.year).must_equal 2099
  end

  it 'limits the lower bound on year to 1980'do
    dos_time = Archive::Zip::DOSTime.new(Time.utc(1000))
    _(dos_time.to_time.year).must_equal 1980
  end

  it 'rejects invalid Integer structures' do
    # Second must not be greater than 29.
    _(proc {
      Archive::Zip::DOSTime.new(epoc | 0b0000000_0000_00000_00000_000000_11110)
    }).must_raise(ArgumentError)

    # Minute must not be greater than 59.
    _(proc {
      Archive::Zip::DOSTime.new(epoc | 0b0000000_0000_00000_00000_111100_00000)
    }).must_raise(ArgumentError)

    # Hour must not be greater than 23.
    _(proc {
      Archive::Zip::DOSTime.new(epoc | 0b0000000_0000_00000_11000_000000_00000)
    }).must_raise(ArgumentError)

    # Day must not be zero.
    _(proc {
      Archive::Zip::DOSTime.new(epoc & 0b1111111_1111_00000_11111_111111_11111)
    }).must_raise(ArgumentError)

    # Month must not be zero.
    _(proc {
      Archive::Zip::DOSTime.new(epoc & 0b1111111_0000_11111_11111_111111_11111)
    }).must_raise(ArgumentError)

    # Month must not be greater than 12.
    _(proc {
      Archive::Zip::DOSTime.new(epoc | 0b0000000_1101_00000_00000_000000_00000)
    }).must_raise(ArgumentError)

    # Year must not be greater than 119.
    _(proc {
      Archive::Zip::DOSTime.new(epoc | 0b1111000_0000_00000_00000_000000_00000)
    }).must_raise(ArgumentError)
  end
end
