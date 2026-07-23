SHELL := /bin/sh

.PHONY: test test-template catalog scaffold-metadata

test:
	sh scripts/test-templates.sh

test-template:
	test -n "$(TEMPLATE)"
	sh scripts/test-templates.sh "$(TEMPLATE)"

# Regenerates .bzync-template.json for any template directory that's
# missing one (never overwrites an existing one — hand edits stick).
scaffold-metadata:
	python3 scripts/scaffold-template-metadata.py

# Rebuilds catalog.json from every template's .bzync-template.json. Run
# this after adding a template or editing its metadata; the marketplace
# reads catalog.json, not the directory tree, so this is the one file
# that needs to be up to date for a change to actually show up.
catalog:
	sh scripts/generate-catalog.sh
