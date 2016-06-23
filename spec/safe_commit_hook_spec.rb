require_relative "../safe_commit_hook"
require "pry"

describe "SafeCommitHook" do
  subject { SafeCommitHook.new.run(args, check_patterns) }
  let(:args) { [] }
  let(:check_patterns) { [] }

  let(:repo) { 'fake_git' }

  before do
    FileUtils.mkdir(repo)
  end

  def create_file_with_name(message)
    File.open("#{repo}/#{message}", 'w') { |f| f.puts("test file contents") }
  end

  after do
    FileUtils.rm_r(repo)
  end

  describe "with no committed passwords" do
    it "detects no false positives" do
      create_file_with_name("ok_file.txt")
      expect { subject }.to_not raise_error
    end
  end

  describe "with filename including rsa" do
    it "returns with exit 1 and prints error" do
      create_file_with_name("id_rsa")
      expect {
        begin
          subject
        rescue SystemExit
        end
      }.to output("Private SSH key: id_rsa\n").to_stdout
    end
  end

  describe "with filename including rsa in several directories"
  describe "with multiple bad filenames caught by the regexes"
  describe "with bad file extension"
  describe "with bad filepath"
  describe "with bad file contents"
end

# extension, type, filename
# regex, match

# filename, extension, path

# whitelist


# file list
# - skip if whitelist
# - check all names

# file list
# - skip if whitelist
# - check contents
