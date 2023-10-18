#!/bin/bash

SAFE_BRANCH="${1:-"zzsafe"}"
SPLIT_FILE="${2:-"experimental/rmoore/split-refs.txt"}"

# get commit hashes for this branch
readarray -t COMMIT_HASHES < <(git log --reverse --format=format:"%H" @{u}..HEAD)

echo "Found ${#COMMIT_HASHES[@]} commits to split"

# make hash->message associative array
declare -A COMMIT_MESSAGES
for COMMIT_HASH in "${COMMIT_HASHES[@]}"; do
    COMMIT_MESSAGES[$COMMIT_HASH]=$(git log --format=%B -n 1 $COMMIT_HASH)
done

SPLIT_PARENT=splitparent-${RANDOM}
bonsai branch ${SAFE_BRANCH}
bonsai branch ${SPLIT_PARENT}

# get set of splits to perform
for SPLIT in $(awk '{print $1}' "${SPLIT_FILE}" | sort -u); do
  # make new branch from safe base
  bonsai branch ${SPLIT_PARENT}
  bonsai branch ${SPLIT}
  for COMMIT_HASH in "${COMMIT_HASHES[@]}"; do
    # apply each commit BUT DON'T ADD
    git show $COMMIT_HASH | git apply
    # get our file list matching the split/branch name and add each one
    for F in $(awk "\$1 == \"$SPLIT\" {print \$2}" $SPLIT_FILE); do
      git add $F
    done
    # commit just added but leave the rest intact so next commit will apply cleanly
    git commit -m "${COMMIT_MESSAGES[$COMMIT_HASH]}"
  done
  # clean up all unadded and wildly altered files
  git restore --staged -- .
  git checkout -- .
done
bonsai branch ${SPILT_PARENT}
