#!/usr/bin/env ruby

class SafeCommitHook
  require 'json'
  WHITELIST_NAME = ".ignored_security_risks"

  def initialize(stdout)
    $stdout = stdout
    @errors = []
  end

  def run(args, check_patterns_file)
    file_basenames = get_file_basenames()

    check_patterns(check_patterns_file).each do |cp|
      case cp["part"]
        when "filename"
          file_basenames.each { |filepath, basename|
            match_result = basename =~ Regexp.new(cp["pattern"])
            if match_result == 0
              add_errors(cp, filepath)
            end
          }
        when "extension"
          file_basenames.select { |filepath, basename|
            if File.extname(basename).gsub(".", "") == cp["pattern"] # this might have to get fancier for regexen
              add_errors(cp, filepath)
            end
          }
        when "path"
          file_basenames.select { |filepath, basename|
            escaped_pattern = cp["pattern"].gsub('\\', '\\\\')
            match_result = File.dirname(filepath) =~ Regexp.new(escaped_pattern)
            if match_result == 0
              add_errors(cp, filepath)
            end
          }
      end
    end
    print_errors_and_exit
  end

  def check_patterns(check_patterns_file)
    JSON.parse(File.read(check_patterns_file))
  end

  def add_errors(cp, filepath)
    @errors << "#{cp["caption"]} in file #{filepath}"
  end

  def print_errors_and_exit
    if @errors.size > 0
      start_red = "\e[31m"
      end_color = "\e[0m"
      puts start_red
      puts "[ERROR] Unable to complete git commit."
      puts "See .git/hooks/pre-commit or https://github.com/compwron/safe-commit-hook-rb for details"
      puts "Add full filepath to .ignored_security_risks to ignore"
      puts @errors
      puts end_color
      exit 1
    else
      print "safe-commit-hook check looks clean. See ignored files in #{WHITELIST_NAME}"
    end
  end

  def get_file_basenames
    files = `git diff --name-only --cached`.split("\n").select { |e| File.file?(e) }
    whitelist = whitelisted_files

    files.inject({}) { |agg, fn|
      basename = File::basename(fn)
      agg[fn] = basename
      agg
    }.reject { |filepath, basename|
      is_git_file?(filepath) || whitelist.include?(filepath)
    }
  end

  def is_git_file?(filepath)
    filepath.split("/")[0] == ".git"
  end

  def whitelisted_files
    whitelists = Dir.glob("**/*", File::FNM_DOTMATCH).select { |f| f.include?(WHITELIST_NAME) }
    files = []
    if whitelists == []
      File.new(WHITELIST_NAME, "w")
      whitelists << WHITELIST_NAME
    end
    whitelists.each { |w|
      files << IO.readlines(w).map(&:strip)
    }
    files.flatten
  end
end

if $PROGRAM_NAME == __FILE__
  check_patterns_file = ARGV[0] || "git-deny-patterns.json"
  SafeCommitHook.new(STDOUT).run(ARGV, check_patterns_file)
end
