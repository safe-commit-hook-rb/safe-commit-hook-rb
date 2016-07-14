#!/usr/bin/env bash

rm -rf end_to_end_test
mkdir end_to_end_test
cd end_to_end_test
pwd
git init
pwd
git status
touch foo.txt
git add foo.txt
git commit -m "File foo"
cp ../../safe_commit_hook.rb .git/hooks/pre-commit
cp ../../git-deny-patterns.json .git/hooks/git-deny-patterns.json
touch id_rsa
git add id_rsa

# the "|| true" makes the script continue running this script (to clean up the directory) after the git commit error
git commit -m "Don't let me commit this bad file, safe-commit-hook-rb!" || true

cd ..
rm -rf end_to_end_test