require "erb"

GENERATED_NODE = "ext/spidermonkey/immutable_node.c"
HOE.clean_globs << GENERATED_NODE
task :check_manifest => GENERATED_NODE

def jsops
  ops = []
  File.open("vendor/spidermonkey/jsopcode.tbl", "rb") { |f|
    f.each_line do |line|
      if line =~ /^OPDEF\((\w+),/
        ops << $1
      end
    end
  }
  ops
end

def tokens
  toks = []
  File.open("vendor/spidermonkey/jsscan.h", "rb") { |f|
    f.each_line do |line|
      line.scan(/TOK_\w+/).each do |token|
        next if token == "TOK_ERROR"
        toks << token
      end
    end
  }
  toks.uniq
end

file GENERATED_NODE => "ext/spidermonkey/immutable_node.c.erb"  do |t|
  template = ERB.new(File.open(t.prerequisites.first, "rb") { |x| x.read })
  File.open(GENERATED_NODE, "wb") { |f| f.write template.result(binding) }
end

file "ext/spidermonkey/extconf.rb" => GENERATED_NODE
