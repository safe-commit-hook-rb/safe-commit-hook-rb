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

  def create_file_in_path(path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    File.new(path, 'w')
  end

  def add_to_whitelist(path)
    whitelist = "#{repo}/.ignored_security_risks"
    `echo #{path} >> #{whitelist}` # TODO use FileUtil here
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

  describe "with check patterns including filename rsa" do
    let(:check_patterns) { [{
                                part: "filename",
                                type: "regex",
                                pattern: '\A.*_rsa\Z',
                                caption: "Private SSH key",
                                description: "null"
                            }] }
    describe "with filename including rsa" do

      it "returns with exit 1 and prints error" do
        create_file_with_name("id_rsa")
        did_exit = false
        expect {
          begin
            subject
          rescue SystemExit
            did_exit = true
          end
        }.to output(/Private SSH key in file .*id_rsa/).to_stdout
        expect(did_exit).to be true
      end
    end
  end

  describe "with regex check pattern for filename" do
    let(:check_patterns) { [{
                                part: "filename",
                                type: "regex",
                                pattern: ".*",
                                caption: "Detected literally everything!",
                                description: "null"
                            }] }
    it "detects file with a name that matches the regex" do
      create_file_with_name("literally-anything")
      did_exit = false
      expect {
        begin
          subject
        rescue SystemExit
          did_exit = true
        end
      }.to output(/Detected literally everything!/).to_stdout
      expect(did_exit).to be true
    end

    xit "accepts whitelisting" do
      create_file_with_name("literally-anything")
      add_to_whitelist("literally-anything")
      expect {
        begin
          subject
        rescue SystemExit
        end
      }.to_not output(/literally-anything/).to_stdout
    end
  end

  describe "with extensions check pattern" do
    let(:check_patterns) { [{
                                part: "extension",
                                type: "match",
                                pattern: "pem",
                                caption: "Potential cryptographic private key",
                                description: "null"
                            }] }
    it "detects file with bad file ending" do
      create_file_with_name("probably_bad.pem")
      did_exit = false
      expect {
        begin
          subject
        rescue SystemExit
          did_exit = true
        end
      }.to output(/Potential cryptographic private key in file .*probably_bad.pem/).to_stdout
      expect(did_exit).to be true
    end

    it "does not detect file with file ending in its name but not actually a bad file ending" do
      create_file_with_name("pem.notpem")
      expect { subject }.to_not raise_error
    end
  end

  describe "with path check pattern" do
    let(:check_patterns) { [{
                                part: "path",
                                type: "regex",
                                pattern: '\A\.?gem/credentials\Z',
                                caption: "Rubygems credentials file",
                                description: "Might contain API key for a rubygems.org account."
                            }] }

    it "does not falsely detect" do
      create_file_in_path("gem/foo/credentials/something.txt")
      expect { subject }.to_not raise_error
    end

    context "with bad path" do
      let(:filepath) { "gem/credentials/something.txt" }

      after do
        FileUtils.rm_r(filepath.split("/")[0])
      end

      it "detects bad path" do
        create_file_in_path(filepath)
        did_exit = false
        expect {
          begin
            subject
          rescue SystemExit
            did_exit = true
          end
        }.to output(/Rubygems credentials file in file gem\/credentials\/something.txt/).to_stdout
        expect(did_exit).to be true
      end
    end
  end
end
