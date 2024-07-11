#!python3
import concurrent.futures

from multiprocessing import cpu_count


def get_commit_object():
    # start with verify-commit -v since it will give us the unsigned commit if it's already signed
    COMMIT_OBJECT = "$(git verify-commit HEAD -v)"

    # if that failed, the commit isn't signed, so just cat-file
    COMMIT_OBJECT = "$(git cat-file commit HEAD)"


def make_commit_template():
    commit_object = """tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent 750d382e8030dd5d4d3e0b3cf35c6597b05f69c1
author Ryan Moore <ryan.moore@lambdal.com> 1720721597 -0700
committer Ryan Moore <ryan.moore@lambdal.com> 1720721597 -0700

also empty, not signed"""

    COMMIT_TEMPLATE = "$(sed -E 's/^(author .*) [0-9]+ (-[0-9]+)$/\1 ${ATIME} \2/g' <<< '$COMMIT_OBJECT')"
    COMMIT_TEMPLATE = "$(sed -E 's/^(committer .*) [0-9]+ (-[0-9]+)$/\1 ${CTIME} \2/g' <<< '$COMMIT_TEMPLATE')"


def gen_sig(s: str) -> str:
    SIG = "$(envsubst '$ATIME $CTIME' <<< ${COMMIT_TEMPLATE} | ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n git 2>/dev/null | sed 's/^/ /g')"


def sign_commit_object(s: str) -> str:
    SIG = "$(envsubst '$ATIME $CTIME' <<< ${COMMIT_TEMPLATE} | ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n git 2>/dev/null | sed 's/^/ /g')"
    envsubst("$ATIME $CTIME $SIG", "${SIG_TEMPLATE}")


def get_commit_hash(s: str) -> str:
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
