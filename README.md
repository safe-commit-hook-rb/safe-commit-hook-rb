[![Build Status](https://travis-ci.org/compwron/safe-commit-hook-rb.svg)](https://travis-ci.org/compwron/safe-commit-hook-rb)

Purpose:
--------

Prevent the accidental check-in of passwords and API keys etc

This tool will not keep you safe. It will just remind you to not shoot yourself in the foot sometimes. I am not a security professional. Be skeptical.

Based on https://github.com/jandre/safe-commit-hook and inspired by https://github.com/michenriksen/gitrob and https://github.com/thoughtworks/talisman


To run the tests:

````
gem install bundler # first time only
bundle install
bundle exec rspec
````

To run the end to end test:

````
cd spec/
./end_to_end_test.sh # should see the output of the commit hook refusing to commit a bad file
````

To use in your project:

````
cp safe_commit_hook.rb <your-project-path>/.git/hooks/pre-commit
cp git-deny-patterns.json <your-project-path>/.git/hooks/git-deny-patterns.json
````

Expected output (for no errors found)

````
safe-commit-hook check looks clean. See ignored files in .ignored_security_risks
````

Expected output (for error found)

````
[ERROR] Unable to complete git commit.
See .git/hooks/pre-commit or https://github.com/compwron/safe-commit-hook-rb for details
Add full filepath to .ignored_security_risks to ignore
Potential cryptographic private key in file foo.pem
````

### Design notes

This is intentionally all one ruby file with no dependencies, so that it will be maximally easy to use as a pre-commit hook.

The check patterns are directly taken from [jandre/safe-commit-hook](https://github.com/jandre/safe-commit-hook) which itself takes from [git-rob](https://github.com/michenriksen/gitrob). I currently have no strategy to pull updates from "upstream".

The generated file .ignored_security_risks is supposed to be checked into your repository. The scary name is on purpose.

This tool currently does not work on windows. It has been tested on OSX. It might work on *nix.

Pull requests are very welcome.

### TODO

optional(?) file text search for:

- entropy (tokenize the file, pick out all the things that only occur once, and then do a frequency count on the characters. If it is obviously not English, or is relatively flat, and is at least some number of characters long, it's probably a key or compressed file or random)
- suspicious strings like "BEGIN RSA PRIVATE KEY"

