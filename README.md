[![Build Status](https://travis-ci.org/compwron/safe-commit-hook-rb.svg)](https://travis-ci.org/compwron/safe-commit-hook-rb)

Purpose:
--------

Prevent the accidental check-in of passwords and API keys etc

Based on https://github.com/jandre/safe-commit-hook and inspired by https://github.com/michenriksen/gitrob and https://github.com/thoughtworks/talisman


To run the tests:

````
gem install bundler # first time only
bundle install
bundle exec rspec
````

To use in your project:

````
cp safe_commit_hook.rb <your-project-path>/.git/hooks/pre-commit
````

### Design notes

This is intentionally all one ruby file with no dependencies, so that it will be maximally easy to use as a pre-commit hook.

The check patterns are directly taken from [jandre/safe-commit-hook](https://github.com/jandre/safe-commit-hook) which itself takes from [git-rob](https://github.com/michenriksen/gitrob). I currently have no strategy to pull updates from "upstream".

Pull requests are very welcome.
