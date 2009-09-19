require "johnson"
require "johnson/cli/options"

module Johnson #:nodoc:
  module CLI #:nodoc:
    JS = IO.read(File.dirname(__FILE__) + "/../../js/johnson/cli.js")
  end
end
