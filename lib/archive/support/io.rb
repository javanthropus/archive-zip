require 'readbytes'

class IO
  # Returns +true+ if the seek method of this IO instance would succeed, +false+
  # otherwise.
  def seekable?
    begin
      pos
      true
    rescue SystemCallError
      false
    end
  end
end
