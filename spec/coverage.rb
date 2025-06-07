require 'simplecov'
SimpleCov.start do
  add_filter %r{^/spec/}

  enable_coverage :branch

  command_name 'minitest'
end
