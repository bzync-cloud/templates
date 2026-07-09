SHELL := /bin/sh

.PHONY: test test-template

test:
	sh scripts/test-templates.sh

test-template:
	test -n "$(TEMPLATE)"
	sh scripts/test-templates.sh "$(TEMPLATE)"
