namespace :test do
  # partial-loads-ok and undef-value-errors necessary to ignore
  # spurious (and eminently ignorable) warnings from the ruby
  # interpreter
  VALGRIND_BASIC_OPTS = "--num-callers=50 --error-limit=no --partial-loads-ok=yes --undef-value-errors=no"

  desc "run test suite under valgrind with basic ruby options"
  task :valgrind => :build do
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-fill ruby options"
  task :valgrind_mem => :build do
    # fill malloced memory with "m" and freed memory with "f"
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=6D --free-fill=66 #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-zero ruby options"
  task :valgrind_mem0 => :build do
    # fill malloced and freed memory with 0
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=00 --free-fill=00 #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under gdb"
  task :gdb => :build do
    cmdline = "gdb --args #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end
end
