require 'stringio'

class StringIO
  # Always returns +true+.  Added for compatibility with IO#seekable?.
  def seekable?
    true
  end
end
