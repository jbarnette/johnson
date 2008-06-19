require "johnson/cli/options"

module Johnson
  module CLI
    JS = IO.read(File.dirname(__FILE__) + "/../../js/johnson/cli.js")
  end
end
