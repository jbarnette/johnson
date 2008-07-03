module Johnson #:nodoc:
  major, minor, tiny = 1, 0, 0
  nano = ENV['RELEASE'] ? nil : Time.now.strftime("%Y%m%d%H%M")
  
  VERSION = [major, minor, tiny, nano].compact.join('.').freeze
end
