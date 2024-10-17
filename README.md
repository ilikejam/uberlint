# uberlint

A universal(ish) code linter, for use manually, in pre-commit, and CI.  
Some righteously opinionated linters for Python, bash, Ansible et al, rolled into a docker container for minimal developer effort.

## Linters

* `ansible-lint` for .yaml and .yml files in ansible trees.  
  Ansible root dirs are detected by the presence of an `ansible.cfg` file, and ansible-lint will be run from each directory where that file is found for the files under it.
* `eslint` for Javascript sources.  
  The `airbnb` style is used, with some reasonable defaults. Due to the questionable way eslint works, the eslintrc from the linted code is replaced and the linter's npm nodules are loaded in with an overlay.
* `rain fmt` format check for Cloudformation files.  
  We only detect yaml/yml files with an `AWSTemplateFormatVersion` declaration, so add any other CF files to `.lintforce` (see below).
* `cfn-lint` lint for Cloudformation files.  
  We only detect yaml/yml files with an `AWSTemplateFormatVersion` declaration, so add any other CF files to `.lintforce` (see below).
* `hadolint` for Dockerfiles.
* `gofmt` for Golang sources.
* `jq` for .json files.  
  Just a syntax check, rather than a style linter.
* `make` for Makefiles.  
  Syntax checking and tests for expected targets.
* `black`, `isort`, and `mypy` for Python sources.
* `rpmlint` for rpm .spec files.
* `shellcheck` for shell scripts.
* `xmllint` for .xml files.
* `yamllint` for yaml files.
* `rubocop` for Ruby sources.
* Files that commonly contain secrets are checked to ensure that they do, in fact, not.
* All files are checked for the AWS key 'AKAI' string.

## Install

* Check this repo out somewhere. We'll refer to that path as `/path/to/this/repo` in this doc.
* Install and run Docker.

## Repo-local config
Optionally, you can add in the repo to be linted's root directory:
* `.pre-commit` - a local script to run before the global linters defined here.
* `.lintignore` - a file containing rsync-style excludes for files to be ignored.  
  This file is processed with `rsync --exclude-from`, so anything that rsync accepts is fair game. Comment lines can start with '#' or ';'.  
  NB: These excludes are _not_ applied to the above `.pre-commit` run.
* `.lintforce` - a file containing lines like:  
  `<linter> <file>`  
  This will force the specified linter to run on the specified file. This is useful for things like Python scripts with no .py extension, which would normally be ignored by the linter's filename matching.  

## Usage

Run `<repo>/lint/show-linters` to see the linter names and short descriptions.

### Git pre-commit
Run:
`git config --global core.hooksPath /path/to/this/repo/lint`
to have the linters run on changed files for every commit globally.

The pre-commit hook will try to pull this repo from master before running to be up to date with the latest hotness, and will pull the latest linter docker image. To disable this behaviour, do `export GLOBALHOOKNOPULL=1`.

### One-shot lint
To lint a full repository, navigate to the repo root and run:  
`/path/to/this/repo/lint/all`

### CI
The docker image that this repo builds is publicly available on AWS ECR, and can be used to lint in a CI context.

In your CI job, run:  
```
docker pull ilikejam/uberlint
docker run --cap-add=SYS_ADMIN -it --rm \
  --env TERM="$TERM" \
  -v "$(pwd)":/repo:ro \
  -u"$(id -u):$(id -g)" \
  ilikejam/uberlint
```  
to lint all of the files in the repo.

## Notes
The container requires `--cap-add=SYS_ADMIN` in order to mount a read-write overlay filesystem over the read-only bind-mount of the code. This allows some linters to work while ensuring that your code is unaffected after the lint run, but without requiring expensive copy operations. The overlay uses /dev/shm as the backing filesystem, so write space could be limited.

## Contribute
Add additional file types/classes as new files in `lint/lib`, following the pattern in the existing files. Should be fairly obvious what's going on. NB: be careful naming the functions - if the function is named the same as the linter binary, you'll likely recurse forever.  
Add any required utils to the Dockerfile.  
The pre-commit and docker scripts have `set -e` enabled, so make sure your linter binary's exit status is tested in the script and call `fail "$file" <linter name>` on failure to allow the hook to continue and ultimately fail at the end.
