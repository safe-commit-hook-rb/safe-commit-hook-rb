#!/usr/bin/env ruby

class SafeCommitHook
  require 'json'
  WHITELIST_NAME = ".ignored_security_risks"

  def initialize(stdout)
    $stdout = stdout
    @errors = []
  end

  def run(repo_full_path, args, check_patterns_file)
    patterns = check_patterns(check_patterns_file)
    whitelisted_files = get_whitelisted_files()
    if args[0] == "check_full"
      # #   starting with most recent commit and working backwards,
      # #     get all file names in each commit
      # #     check_staged_files(check_patterns_file, file_basenames())
      # commit_hashes = `git log --pretty=format:%h`.split
      # commit_hashes.each { |commit_hash|
      #   files_in_commit = `git diff-tree --no-commit-id --name-only -r #{commit_hash}`.split
      #   check_staged_files(patterns, file_basenames(files_in_commit, whitelisted_files), commit_hash)
      # }
    end
    check_staged_files(patterns, get_staged_file_basenames(repo_full_path, whitelisted_files), "currently staged files")
    print_errors_and_exit
  end

  def check_staged_files(check_patterns, file_basenames, commit_hash)
    check_patterns.each do |cp|
      case cp["part"]
        when "filename"
          file_basenames.each { |filepath, basename|
            match_result = basename =~ Regexp.new(cp["pattern"])
            if match_result == 0
              add_errors(cp, filepath, commit_hash)
            end
          }
        when "extension"
          file_basenames.select { |filepath, basename|
            if File.extname(basename).gsub(".", "") == cp["pattern"] # this might have to get fancier for regexen
              add_errors(cp, filepath, commit_hash)
            end
          }
        when "path"
          file_basenames.select { |filepath, basename|
            escaped_pattern = cp["pattern"].gsub('\\', '\\\\')
            match_result = File.dirname(filepath) =~ Regexp.new(escaped_pattern)
            if match_result == 0
              add_errors(cp, filepath, commit_hash)
            end
          }
      end
    end
  end

  private

  def check_patterns(check_patterns_file)
    JSON.parse(File.read(check_patterns_file))
  end

  def add_errors(cp, filepath, commit_hash)
    @errors << "#{cp["caption"]} in file #{filepath} in commit #{commit_hash}"
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

  def get_file_basenames(files, whitelist)
    files.inject({}) { |agg, fn|
      basename = File::basename(fn)
      agg[fn] = basename
      agg
    }.reject { |filepath, basename|
      is_git_file?(filepath) || whitelist.include?(filepath)
    }
  end

  def get_staged_file_basenames(repo_full_path, whitelisted_files)
    files = `cd #{repo_full_path} && git diff --name-only --cached`.split("\n").select { |e| File.file?(e) }
    get_file_basenames(files, whitelisted_files)
  end

  def is_git_file?(filepath)
    filepath.split("/")[0] == ".git"
  end

  def get_whitelisted_files
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
  check_patterns_file = ARGV[0] || ".git/hooks/git-deny-patterns.json"
  SafeCommitHook.new(STDOUT).run(ARGV, check_patterns_file)
end
