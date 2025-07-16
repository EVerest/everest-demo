Contributing to kas
===================

Contributions to kas are always welcome. This document explains the
general requirements on contributions and the recommended preparation
steps. It also sketches the typical integration process of patches.


Contribution Checklist
----------------------

- use git to manage your changes [*recommended*]

- follow Python coding style outlined in pep8 [**required**]

- add the required copyright header to each new file introduced, see
  [licensing information](LICENSE) [**required**]

- structure patches logically, in small steps [**required**]
    - one separable functionality/fix/refactoring = one patch
    - do not mix those there in a single patch
    - after each patch, the tree still has to build and work, i.e. do not add
      even temporary breakages inside a patch series (helps when tracking down
      bugs)
    - use `git rebase -i` to restructure a patch series

- base patches on top of latest master or - if there are dependencies - on next
  (note: next is an integration branch that may change non-linearly)

- test patches sufficiently (obvious, but...) [**required**]
    - no regressions are caused in affected code
    - the world is still spinning

- add signed-off to all patches [**required**]
    - to certify the "Developer's Certificate of Origin", see below
    - check with your employer when not working on your own!

- post patches to mailing list [**required**]
    - use `git format-patch/send-email` if possible
    - send patches inline, do not append them
    - no HTML emails!
    - CC people who you think should look at the patches, e.g.
      - someone who wrote a change that is fixed or reverted by you now
      - who commented on related changes in the recent past
      - who otherwise has expertise and is interested in the topic
    - pull requests on github are only optional

- post follow-up version(s) if feedback requires this

- send reminder if nothing happened after about a week


Developer's Certificate of Origin 1.1
-------------------------------------

When signing-off a patch for this project like this

    Signed-off-by: Random J Developer <random@developer.example.org>

using your real name (no pseudonyms or anonymous contributions), you declare the
following:

    By making a contribution to this project, I certify that:

        (a) The contribution was created in whole or in part by me and I
            have the right to submit it under the open source license
            indicated in the file; or

        (b) The contribution is based upon previous work that, to the best
            of my knowledge, is covered under an appropriate open source
            license and I have the right under that license to submit that
            work with modifications, whether created in whole or in part
            by me, under the same open source license (unless I am
            permitted to submit under a different license), as indicated
            in the file; or

        (c) The contribution was provided directly to me by some other
            person who certified (a), (b) or (c) and I have not modified
            it.

        (d) I understand and agree that this project and the contribution
            are public and that a record of the contribution (including all
            personal information I submit with it, including my sign-off) is
            maintained indefinitely and may be redistributed consistent with
            this project or the open source license(s) involved.


Contribution Integration Process
--------------------------------

1. patch reviews performed on mailing list
    * at least by maintainers, but everyone is invited
    * feedback has to consider design, functionality and style
    * simpler and clearer code preferred, even if original code works fine

2. accepted patches merged into next branch

3. further testing done by community, including CI build tests and code
   analyzer runs

4. if no new problems or discussions showed up, acceptance into master
    * grace period for master: about 3 days
    * urgent fixes may be applied sooner

github facilities are not used for the review process so that people can follow
all changes and related discussions at a single stop, the mailing list. This
may change in the future if github should improve their email integration.


Send patches to: kas-devel@googlegroups.com

Archive: https://groups.google.com/d/forum/kas-devel

Subscription:
 - kas-devel+subscribe@googlegroups.com
 - https://groups.google.com/forum/#!forum/kas-devel/join
