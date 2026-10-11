# Contributing to backbone-rest

## Branches

`support/0.x` maintains the project's v1 implementation, starting from package 0.7.2. `master` is the v2 migration integration line. The HTTP/REST v2 port is not complete.

Commit work in coherent batches. Apply applicable fixes to the support line individually; do not merge v2 changes into it. A merge into master is not a release.

Support releases must use the `support-0` npm dist-tag. The publish guard rejects a missing or different tag on the support branch. Existing build and test commands remain unchanged. Publishing, version changes and tags belong to the maintainer.
