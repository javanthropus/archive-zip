# encoding: UTF-8

require 'stringio'

##
# This extends StringIO to include additional methods required by the io-like
# library to wrap IO objects.
class StringIO
  unless public_method_defined?(:sysseek)
    def sysseek(offset, whence = IO::SEEK_SET)
      seek(offset, whence)
      pos
    end
  end

  unless public_method_defined?(:nonblock?)
    def nonblock?
      false
    end
  end

  unless public_method_defined?(:wait)
    def wait(*args)
      return true
    end
  end
end
