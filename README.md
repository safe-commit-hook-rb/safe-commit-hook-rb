[![Build Status](https://travis-ci.org/compwron/safe-commit-hook-rb.svg)](https://travis-ci.org/compwron/safe-commit-hook-rb)

Purpose:
--------

Prevent the accidental check-in of passwords and API keys etc

Based on https://github.com/jandre/safe-commit-hook and inspired by https://github.com/michenriksen/gitrob and https://github.com/thoughtworks/talisman


To run the tests:

````
gem install bundler # first time only
bundle install
rspec
````

To use in your project:

````
cp safe_commit_hook.rb <your-project-path>/.git/hooks/pre-commit
````
