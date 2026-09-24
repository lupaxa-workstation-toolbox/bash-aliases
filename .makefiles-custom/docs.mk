# This repo is Bash + MkDocs, not a Python package. The library
# python-install-dev target needs -e ".[dev]" and pyproject.toml.

PIP ?= python3 -m pip

.PHONY: python-install-dev help help-python-install

python-install-dev:
	$(PIP) install -r requirements.txt

help-python-install:
	$(call mf_help_header,Development extras:)
	$(call mf_help_line,python-install-dev,Install MkDocs from requirements.txt)
	@echo

help: help-python-install
