#!/usr/bin/env ruby

class SafeCommitHook
  require 'json'
  WHITELIST_NAME = ".ignored_security_risks"

  def initialize(stdout)
    $stdout = stdout
    @errors = []
  end

  def run(repo_full_path, check_all_commits, check_patterns_file)
    check_patterns = check_patterns(check_patterns_file)
    whitelist = whitelisted_files
    if check_all_commits
      check_all_commits(check_patterns, repo_full_path, whitelist)
    end
    staged_file_basenames = get_staged_file_basenames(repo_full_path, whitelist)
    check_files(check_patterns, staged_file_basenames)
    print_errors_and_exit
  end

  def check_all_commits(check_patterns, repo_full_path, whitelist)
    commit_hashes = `cd #{repo_full_path} && git log --pretty=format:%h`.split
    commit_hashes.each { |commit_hash|
      files = `cd #{repo_full_path} && git show --pretty="" --name-only -r #{commit_hash}`.split
      commit_files_basenames = basenames(files, whitelist)
      check_files(check_patterns, commit_files_basenames)
    }
  end

  def check_files(check_patterns, file_basenames)
    check_patterns.each do |cp|
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
  end

  private

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

  def get_staged_file_basenames(repo_full_path, whitelist)
    files = `cd #{repo_full_path} && git diff --name-only --cached`.split("\n")
    basenames(files, whitelist)
  end

  def basenames(files, whitelist)
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
  check_patterns_file = ENV["GIT_DENY_PATTERNS"] || ".git/hooks/git-deny-patterns.json"
  check_all_commits = ENV["CHECK_ALL_COMMITS"]
  SafeCommitHook.new(STDOUT).run(`pwd`.strip, check_all_commits, check_patterns_file)
end
