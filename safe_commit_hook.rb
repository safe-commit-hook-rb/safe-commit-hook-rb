#!/usr/bin/env ruby

class SafeCommitHook
  WHITELIST_NAME = ".ignored_security_risks"

  def run(args, check_patterns)
    errors = []

    file_basenames = get_file_basenames()

    check_patterns.each do |cp|
      case cp[:part]
        when "filename"
          file_basenames.select { |filepath, basename|
            escaped_pattern = cp[:pattern].gsub('\\', '\\\\')
            match_result = basename =~ Regexp.new(escaped_pattern)
            match_result == 0
          }.each { |filepath, basename|
            errors << "#{cp[:caption]} in file #{filepath}"
          }
        when "extension"
          file_basenames.select { |filepath, basename|
            File.extname(basename).gsub(".", "") == cp[:pattern] # this might have to get fancier for regexen
          }.each { |filepath, basename|
            errors << "#{cp[:caption]} in file #{filepath}"
          }
        when "path"
          file_basenames.select { |filepath, basename|
            escaped_pattern = cp[:pattern].gsub('\\', '\\\\')
            match_result = File.dirname(filepath) =~ Regexp.new(escaped_pattern)
            match_result == 0
          }.each { |filepath, basename|
            errors << "#{cp[:caption]} in file #{filepath}"
          }
      end
    end
    print_errors_and_exit(errors)
  end

  def print_errors_and_exit(errors)
    if errors.size > 0
      start_red = "\e[31m"
      end_color = "\e[0m"
      puts start_red
      puts "[ERROR] Unable to complete git commit."
      puts "See .git/hooks/pre-commit or https://github.com/compwron/safe-commit-hook-rb for details"
      puts "Add full filepath to .ignored_security_risks to ignore"
      puts errors
      puts end_color
      exit 1
    end
  end

  def get_file_basenames
    files = Dir.glob("**/*", File::FNM_DOTMATCH).select { |e| File.file?(e) }
    whitelist = whitelisted_files(files)

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

  def whitelisted_files(files)
    whitelist = files.find { |fn|
      fn.include?(WHITELIST_NAME)
    }

    unless whitelist
      File.open(WHITELIST_NAME, "w")
    end
    IO.readlines(WHITELIST_NAME).map(&:strip)
  end
end

CHECK_PATTERNS = [
    {
        part: "filename",
        type: "regex",
        pattern: "\A.*_rsa\Z",
        caption: "Private SSH key",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A.*_dsa\Z",
        caption: "Private SSH key",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A.*_ed25519\Z",
        caption: "Private SSH key",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A.*_ecdsa\Z",
        caption: "Private SSH key",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "pem",
        caption: "Potential cryptographic private key",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "ppk",
        caption: "Potential cryptographic private key",
        description: "null"
    },
    {
        part: "extension",
        type: "regex",
        pattern: "\Akey(pair)?\Z",
        caption: "Potential cryptographic private key",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "pkcs12",
        caption: "Potential cryptographic key bundle",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "pfx",
        caption: "Potential cryptographic key bundle",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "p12",
        caption: "Potential cryptographic key bundle",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "asc",
        caption: "Potential cryptographic key bundle",
        description: "null"
    },
    {
        part: "filename",
        type: "match",
        pattern: "otr.private_key",
        caption: "Pidgin OTR private key",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?(bash_|zsh_|z)?history\Z",
        caption: "Shell command history file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?mysql_history\Z",
        caption: "MySQL client command history file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?psql_history\Z",
        caption: "PostgreSQL client command history file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?irb_history\Z",
        caption: "Ruby IRB console history file",
        description: "null"
    },
    {
        part: "path",
        type: "regex",
        pattern: "\.?purple\/accounts\.xml\Z",
        caption: "Pidgin chat client account configuration file",
        description: "null"
    },
    {
        part: "path",
        type: "regex",
        pattern: "\.?xchat2?\/servlist_?\.conf\Z",
        caption: "Hexchat/XChat IRC client server list configuration file",
        description: "null"
    },
    {
        part: "path",
        type: "regex",
        pattern: "\.?irssi\/config\Z",
        caption: "Irssi IRC client configuration file",
        description: "null"
    },
    {
        part: "path",
        type: "regex",
        pattern: "\.?recon-ng\/keys\.db\Z",
        caption: "Recon-ng web reconnaissance framework API key database",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?dbeaver-data-sources.xml\Z",
        caption: "DBeaver SQL database manager configuration file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?muttrc\Z",
        caption: "Mutt e-mail client configuration file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?s3cfg\Z",
        caption: "S3cmd configuration file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?trc\Z",
        caption: "T command-line Twitter client configuration file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "ovpn",
        caption: "OpenVPN client configuration file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?gitrobrc\Z",
        caption: "Well, this is awkward... Gitrob configuration file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?(bash|zsh)rc\Z",
        caption: "Shell configuration file",
        description: "Shell configuration files might contain information such as server hostnames, passwords and API keys."
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?(bash_|zsh_)?profile\Z",
        caption: "Shell profile configuration file",
        description: "Shell configuration files might contain information such as server hostnames, passwords and API keys."
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?(bash_|zsh_)?aliases\Z",
        caption: "Shell command alias configuration file",
        description: "Shell configuration files might contain information such as server hostnames, passwords and API keys."
    },
    {
        part: "filename",
        type: "match",
        pattern: "secret_token.rb",
        caption: "Ruby On Rails secret token configuration file",
        description: "If the Rails secret token is known, it can allow for remote code execution. (http://www.exploit-db.com/exploits/27527/)"
    },
    {
        part: "filename",
        type: "match",
        pattern: "omniauth.rb",
        caption: "OmniAuth configuration file",
        description: "The OmniAuth configuration file might contain client application secrets."
    },
    {
        part: "filename",
        type: "match",
        pattern: "carrierwave.rb",
        caption: "Carrierwave configuration file",
        description: "Can contain credentials for online storage systems such as Amazon S3 and Google Storage."
    },
    {
        part: "filename",
        type: "match",
        pattern: "schema.rb",
        caption: "Ruby On Rails database schema file",
        description: "Contains information on the database schema of a Ruby On Rails application."
    },
    {
        part: "filename",
        type: "match",
        pattern: "database.yml",
        caption: "Potential Ruby On Rails database configuration file",
        description: "Might contain database credentials."
    },
    {
        part: "filename",
        type: "match",
        pattern: "settings.py",
        caption: "Django configuration file",
        description: "Might contain database credentials, online storage system credentials, secret keys, etc."
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A(.*)?config(\.inc)?\.php\Z",
        caption: "PHP configuration file",
        description: "Might contain credentials and keys."
    },
    {
        part: "extension",
        type: "match",
        pattern: "kdb",
        caption: "KeePass password manager database file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "agilekeychain",
        caption: "1Password password manager database file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "keychain",
        caption: "Apple Keychain database file",
        description: "null"
    },
    {
        part: "extension",
        type: "regex",
        pattern: "\Akey(store|ring)\Z",
        caption: "GNOME Keyring database file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "log",
        caption: "Log file",
        description: "Log files might contain information such as references to secret HTTP endpoints, session IDs, user information, passwords and API keys."
    },
    {
        part: "extension",
        type: "match",
        pattern: "pcap",
        caption: "Network traffic capture file",
        description: "null"
    },
    {
        part: "extension",
        type: "regex",
        pattern: "\Asql(dump)?\Z",
        caption: "SQL dump file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "gnucash",
        caption: "GnuCash database file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "backup",
        caption: "Contains word: backup",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "dump",
        caption: "Contains word: dump",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "password",
        caption: "Contains word: password",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "private.*key",
        caption: "Contains words: private, key",
        description: "null"
    },
    {
        part: "filename",
        type: "match",
        pattern: "jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml",
        caption: "Jenkins publish over SSH plugin file",
        description: "null"
    },
    {
        part: "filename",
        type: "match",
        pattern: "credentials.xml",
        caption: "Potential Jenkins credentials file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?htpasswd\Z",
        caption: "Apache htpasswd file",
        description: "null"
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A\.?netrc\Z",
        caption: "Configuration file for auto-login process",
        description: "Might contain username and password."
    },
    {
        part: "extension",
        type: "match",
        pattern: "kwallet",
        caption: "KDE Wallet Manager database file",
        description: "null"
    },
    {
        part: "filename",
        type: "match",
        pattern: "LocalSettings.php",
        caption: "Potential MediaWiki configuration file",
        description: "null"
    },
    {
        part: "extension",
        type: "match",
        pattern: "tblk",
        caption: "Tunnelblick VPN configuration file",
        description: "null"
    },
    {
        part: "path",
        type: "regex",
        pattern: "\A\.?gem/credentials\Z",
        caption: "Rubygems credentials file",
        description: "Might contain API key for a rubygems.org account."
    },
    {
        part: "filename",
        type: "regex",
        pattern: "\A.*\.pubxml(\.user)?\Z",
        caption: "Potential MSBuild publish profile",
        description: "null"
    },
    {
        part: "filename",
        type: "match",
        pattern: ".env",
        caption: "PHP dotenv",
        description: "Environment file that contains sensitive data"
    }
]

if $PROGRAM_NAME == __FILE__
  SafeCommitHook.new.run(ARGV, CHECK_PATTERNS)
end
