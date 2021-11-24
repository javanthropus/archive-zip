# encoding: UTF-8

module Archive; class Zip
# A representation of the DOS time structure which can be converted into
# instances of Time.
class DOSTime
  include Comparable

  # Creates a new instance of DOSTime.  _dos_time_ is a 4 byte String or
  # unsigned number (Integer) representing an MS-DOS time structure where:
  # Bits 0-4::   2 second increments (0-29)
  # Bits 5-10::  minutes (0-59)
  # Bits 11-15:: hours (0-24)
  # Bits 16-20:: day (1-31)
  # Bits 21-24:: month (1-12)
  # Bits 25-31:: four digit year minus 1980 (0-119)
  #
  # If _dos_time_ is ommitted or +nil+, a new instance is created based on the
  # current time.
  def initialize(time = nil)
    @dos_time = case time
                when nil
                  from_time(Time.now)
                when Time
                  from_time(time)
                else
                  time
                end

    validate
  end

  # Returns 1 if _other_ is a time earlier than this one, 0 if _other_ is the
  # same time, and -1 if _other_ is a later time.
  def cmp(other)
    raise ArgumentError, 'other must be a DOSTime' unless DOSTime === other
    to_i <=> other.to_i
  end
  alias_method :<=>, :cmp

  # Returns the time value of this object as an integer representing the DOS
  # time structure.
  def to_i
    @dos_time
  end

  # Returns a Time instance which is equivalent to the time represented by
  # this object.
  def to_time
    second = ((0b11111         & @dos_time)      ) * 2
    minute = ((0b111111  << 5  & @dos_time) >>  5)
    hour   = ((0b11111   << 11 & @dos_time) >> 11)
    day    = ((0b11111   << 16 & @dos_time) >> 16)
    month  = ((0b1111    << 21 & @dos_time) >> 21)
    year   = ((0b1111111 << 25 & @dos_time) >> 25) + 1980
    return Time.local(year, month, day, hour, minute, second)
  end

  private

  # Converts an instance of Time into a DOS date-time structure.  Times are
  # bracketed by the limits of the ability of the DOS date-time structure to
  # represent them.  Accuracy is 2 seconds and years range from 1980 to 2099.
  def from_time(time)
    dos_sec  = time.sec/2
    dos_year = time.year - 1980
    dos_year = 0   if dos_year < 0
    dos_year = 119 if dos_year > 119

    (dos_sec         ) |
    (time.min   <<  5) |
    (time.hour  << 11) |
    (time.day   << 16) |
    (time.month << 21) |
    (dos_year   << 25)
  end

  def validate
    second = (0b11111         & @dos_time)
    minute = (0b111111  << 5  & @dos_time) >>  5
    hour   = (0b11111   << 11 & @dos_time) >> 11
    day    = (0b11111   << 16 & @dos_time) >> 16
    month  = (0b1111    << 21 & @dos_time) >> 21
    year   = (0b1111111 << 25 & @dos_time) >> 25

    if second > 29
      raise ArgumentError, 'second must not be greater than 29'
    elsif minute > 59
      raise ArgumentError, 'minute must not be greater than 59'
    elsif hour > 23
      raise ArgumentError, 'hour must not be greater than 23'
    elsif day < 1
      raise ArgumentError, 'day must not be less than 1'
    elsif month < 1
      raise ArgumentError, 'month must not be less than 1'
    elsif month > 12
      raise ArgumentError, 'month must not be greater than 12'
    elsif year > 119
      raise ArgumentError, 'year must not be greater than 119'
    end
  end
end
end; end
