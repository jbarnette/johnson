namespace :test do
  # partial-loads-ok and undef-value-errors necessary to ignore
  # spurious (and eminently ignorable) warnings from the ruby
  # interpreter
  VALGRIND_BASIC_OPTS = "--num-callers=50 --error-limit=no --partial-loads-ok=yes --undef-value-errors=no"

  desc "run test suite under valgrind with basic ruby options"
  task :valgrind => :compile do
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} ruby #{HOE.make_test_cmd}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-fill ruby options"
  task :valgrind_mem => :compile do
    # fill malloced memory with "m" and freed memory with "f"
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=6D --free-fill=66 ruby #{HOE.make_test_cmd}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-zero ruby options"
  task :valgrind_mem0 => :compile do
    # fill malloced and freed memory with 0
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=00 --free-fill=00 ruby #{HOE.make_test_cmd}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under gdb"
  task :gdb => :compile do
    cmdline = "gdb --args ruby #{HOE.make_test_cmd}"
    puts cmdline
    system cmdline
  end
end
