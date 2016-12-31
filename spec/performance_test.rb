#!/usr/bin/env ruby


# mkdir
# git init
# put in commithook
# add and stage 1, 10, 100, 1000, 10000 etc files
# try to commit and save timestamps
# prettyprint

# test all files clean
# test all files bad in each of the 3 ways
# test all files random clean/bad

# test generate every problem?

def cleanup(dir)
  `rm -rf #{dir}`
end

def setup(dir)
  `mkdir #{dir} && cd #{dir} && git init`
  `cd #{dir} && cp ../../safe_commit_hook.rb .git/hooks/pre-commit`
  `cd #{dir} && cp ../../git-deny-patterns.json .git/hooks/git-deny-patterns.json`
end

def test_duration(dir, x)
  setup(dir)
  goto_dir = "cd #{dir} && "

  0.upto(x).each_slice(1000).map { |arr| # avoiding Errno::E2BIG cmd too big
    cmd = goto_dir + arr.map { |i|
      "touch #{i}_dsa"
    }.join(' && ') + ' && git add .'
    `#{cmd}`
    p "created files for #{arr.count} files"
  }
  `cd #{dir} && git add .`
  puts 'Starting commit run'
  before_time = Time.now
  `cd #{dir} && git commit -m "testing commit hook"`
  after_time = Time.now
  puts "\nEnding commit run"
  duration = after_time - before_time
  cleanup(dir)
  duration
end

dir = 'perf-test-tmp'
x = 100000
duration = test_duration(dir, x)
puts "\nDuration for #{x} files: #{duration}"

# With no detected errors
# Duration for 10000 files: 2.755976
# Duration for 100000 files: 30.908965

# With all files containing errors:
# Duration for 10000 files: 4.034943
# Duration for 100000 files: 27.153732
