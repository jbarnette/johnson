module Johnson #:nodoc:
  # FIXME: Don't add the timestamp for "release" versions
  VERSION = "1.0.0.#{Time.now.strftime("%Y%m%d%H%M")}".freeze
end
