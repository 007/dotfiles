#!/bin/bash
set -e
cd ~/src/av
bazel run //experimental/rmoore/tools/monorepo:safe_pull_point > .git/safe_pull2
mv .git/safe_pull2 .git/safe_pull
