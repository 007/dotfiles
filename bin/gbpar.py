#!/usr/bin/env python3

import concurrent.futures
import os
import re
import subprocess
import sys
from multiprocessing import cpu_count
from typing import List


def run_command(cmd: List[str], *, stdin: str = None) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True, input=stdin)
    if p.returncode == 0:
        return p.stdout
    return None


def get_commit_object():
    o = run_command(["git", "verify-commit", "HEAD", "-v"])
    if o is None:
        o = run_command(["git", "cat-file", "commit", "HEAD"])
    return o.rstrip()


def make_commit_template(commit_object: str = None) -> str:
    if commit_object is None:
        commit_object = get_commit_object()

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
    filled_template = s.format(atime=atime, ctime=ctime, gpgsig="")
    signature = gen_sig(filled_template)

    # Prepend a space to each line of the output
    signed_output = "\n".join(" " + line for line in signature.split("\n"))

    # no space after gpgsig since signed_output is already padded
    # BUT we do need to append \n since we needed to strip the extra CR to avoid " \n" extra padding
    signed_output = s.format(atime=atime, ctime=ctime, gpgsig="gpgsig" + signed_output + "\n")
    return signed_output


def get_commit_hash(s: str) -> str:
    get_hash_cmd = ["git", "hash-object", "-t", "commit", "--stdin"]
    git_hash = run_command(get_hash_cmd, stdin=s)
    return git_hash


def get_commit_atime(commit="HEAD"):
    atime_cmd = ["git", "log", "-n1", commit, "--format=%at"]
    atime = run_command(atime_cmd)
    return int(atime)


def get_commit_ctime(commit="HEAD"):
    ctime_cmd = ["git", "log", "-n1", commit, "--format=%ct"]
    ctime = run_command(ctime_cmd)
    return int(ctime)


def check_in_with_ctime_atime(*, ctime, atime):
    os.environ["GIT_COMMITTER_DATE"] = str(ctime)
    commit_cmd = ["git", "commit", "--amend", "--no-edit", "--allow-empty", "--gpg-sign", f"--date={atime}"]
    result = run_command(commit_cmd)
    return result


def check_sig(template, atime, ctime, desired_match):
    signed_obj = sign_commit_object(template, atime=atime, ctime=ctime)
    commit_hash = get_commit_hash(signed_obj)
    if commit_hash.startswith(desired_match):
        print(f"GIT_COMMITTER_DATE={ctime} git commit --amend --no-edit --allow-empty --gpg-sign --date={atime}")
        sys.exit(0)
        return True
    return False


def pairwise_explore_range(range_max=10):
    # efficient-ish minimum-ish range exploration
    # tends to yield smaller sums before larger ones
    for x in range(0, range_max + 1):
        for i in range(x):
            yield (i,x)
        for j in range(x + 1):
            yield (x, j)



def match_sig():
    template = make_commit_template()
    start_atime = get_commit_atime()

    with concurrent.futures.ProcessPoolExecutor(max_workers=12) as executor:
        for delta_a, delta_c in pairwise_explore_range(86400 // 2):
            atime = start_atime - delta_a
            ctime = atime + delta_c
            executor.submit(check_sig, template, atime, ctime, "007")


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
    match_sig()
    # o = run_command(["git", "cat-file", "commit", "HEAD^"])
    # ohash = get_commit_hash(o)

    # t = make_commit_template()
    # signed_obj = sign_commit_object(t, atime=1720651680, ctime=1720651736)
    # print(signed_obj == o)
