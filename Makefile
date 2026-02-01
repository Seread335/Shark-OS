# Makefile - common targets for Shark OS repo
.PHONY: all lint test clean ci

all: lint test

lint:
	bash scripts/ci/run-shellcheck.sh
	# Syntax check
	find . -name '*.sh' -type f -print0 | xargs -0 -n1 -P4 bash -n

test:
	bash tests/functional-cli-tests.sh || true

clean:
	bash scripts/maintenance/clean-build.sh

ci: lint test