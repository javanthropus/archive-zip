require 'stringio'

class StringIO
  unless StringIO.method_defined?(:readbytes)
    # Copied from IO#readbytes.
    def readbytes(n)
      str = read(n)
      if str == nil
        raise EOFError, "end of file reached"
      end
      if str.size < n
        raise TruncatedDataError.new("data truncated", str)
      end
      str
    end
  end

  # Always returns +true+.  Added for compatibility with IO#seekable?.
  def seekable?
    true
  end
end
