#!/usr/bin/env python3

import concurrent.futures
import os
import re
import subprocess
from multiprocessing import cpu_count
from typing import List


def run_command(cmd: List[str], *, stdin: str = None) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True, input=stdin)
    if p.returncode == 0:
        return p.stdout
    return None


def get_commit_object():
    o = run_command(["git", "verify-commit", "HEAD^", "-v"])
    if o is None:
        o = run_command(["git", "cat-file", "commit", "HEAD^"])
    return o.rstrip()


def make_commit_template(commit_object: str = None) -> str:
    if commit_object is None:
        commit_object = get_commit_object()
    print(f"original was '{commit_object}'")

    done_with_headers = False
    commit_template = []
    for l in commit_object.split("\n"):
        if not done_with_headers:
            if l == "":
                done_with_headers = True
                commit_template.append("{gpgsig}")
                continue

            l = re.sub(r"^(author .*) [0-9]+ (-[0-9]+)$", r"\1 {atime} \2", l)
            l = re.sub(r"^(committer .*) [0-9]+ (-[0-9]+)$", r"\1 {ctime} \2", l)

        commit_template.append(l)

    return "\n".join(commit_template) + "\n"


def gen_sig(s: str) -> str:
    ssh_keygen_cmd = ["ssh-keygen", "-Y", "sign", "-f", os.path.expanduser("~/.ssh/id_ed25519"), "-n", "git"]
    result = run_command(ssh_keygen_cmd, stdin=s)
    return result.rstrip()


def sign_commit_object(s: str, *, atime: int, ctime: int) -> str:
    filled_template = s.format(atime=atime, ctime=ctime, gpgsig='')
    print(f"signing '{filled_template}'")
    signature = gen_sig(filled_template)
    print(f"got signature '{signature}'")

    # Prepend a space to each line of the output
    signed_output = "\n".join(" " + line for line in signature.split("\n"))

    # no space after gpgsig since signed_output is already padded
    # BUT we do need to append \n since we needed to strip the extra CR to avoid " \n" extra padding
    signed_output = s.format(atime=atime, ctime=ctime, gpgsig="gpgsig" + signed_output + "\n")
    return signed_output


def get_commit_hash(s: str) -> str:

    print(f"Checking hash of '{s}'")
    get_hash_cmd = ["git", "hash-object", "-t", "commit", "--stdin"]
    git_hash = run_command(get_hash_cmd, stdin=s)
    print(f"Generated hash {git_hash}")
    return git_hash
    command = """
    git hash-object -t commit --stdin | \
    grep -q ^007 && \
    (
      GIT_COMMITTER_DATE="$CTIME" git commit --amend --no-edit --allow-empty --date="$ATIME" > /dev/null && \
      git rev-parse HEAD
    ) && \
    exit
"""


def get_commit_atime(commit="HEAD"):
    return git(f"log -n1 {commit} --format=%at")


def get_commit_ctime(commit="HEAD"):
    return git(f"log -n1 {commit} --format=%ct")


def check_sig(atime, ctime):

    return get_commit_atime() == 123


#
#   export SIG="$(envsubst '$ATIME $CTIME' <<< "${COMMIT_TEMPLATE}" | ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n git 2>/dev/null | sed 's/^/ /g')"
#   export SIG_TEMPLATE="$(sed -E 's/^(committer .*)$/\1\ngpgsig${SIG}/g' <<< "$COMMIT_TEMPLATE")"
#   envsubst '$ATIME $CTIME $SIG' <<< "${SIG_TEMPLATE}" | \
#     git hash-object -t commit --stdin | \
#     grep -q ^007 && \
#     (
#       GIT_COMMITTER_DATE="$CTIME" git commit --amend --no-edit --allow-empty --date="$ATIME" > /dev/null && \
#       git rev-parse HEAD
#     ) && \
#     exit


# def match_sig():
#     with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
#         visited.add(website_to_crawl)
#         not_done = {executor.submit(get_links, website_to_crawl): website_to_crawl}
#
#         while len(not_done) > 0:
#             done, not_done = concurrent.futures.wait(
#                 not_done, return_when=concurrent.futures.FIRST_COMPLETED
#             )
#             for future in done:
#                 for x in future.result():
#                     clean_url = x.split("#")[0]
#                     parts = urlparse(clean_url)
#                     if parts.hostname == base_domain:
#                         if not clean_url in visited:
#                             visited.add(clean_url)
#                             not_done.add(executor.submit(get_links, clean_url))
#
# export -f check_sig
#
# parallel -j 400% check_sig ::: $(seq $ATIME $((ATIME - 4320))) ::: $(seq $CTIME $((CTIME + 4320)))
#
# def crawl_website_actually_parallel(url:str) -> List[str]:
#     base_domain = urlparse(url).hostname
#     print(f"Crawling {url} and filtering for {base_domain}")
#     visited = set()
#
#     with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
#         visited.add(website_to_crawl)
#         not_done = {executor.submit(get_links, website_to_crawl):website_to_crawl}
#
#         while len(not_done) > 0:
#             done, not_done = concurrent.futures.wait(not_done, return_when=concurrent.futures.FIRST_COMPLETED)
#             for future in done:
#                 for x in future.result():
#                     clean_url = x.split("#")[0]
#                     parts = urlparse(clean_url)
#                     if parts.hostname == base_domain:
#                         if not clean_url in visited:
#                             visited.add(clean_url)
#                             not_done.add(executor.submit(get_links, clean_url))
#
#     return list(visited)
if __name__ == "__main__":
    o = run_command(["git", "cat-file", "commit", "HEAD^"])
    ohash = get_commit_hash(o)

    t = make_commit_template()
    signed_obj = sign_commit_object(t, atime=1720651680, ctime=1720651736)
    print(signed_obj == o)
