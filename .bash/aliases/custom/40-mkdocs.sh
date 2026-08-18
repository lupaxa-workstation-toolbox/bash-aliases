# shellcheck shell=bash
###############################################################################
# 40-mkdocs.sh — MkDocs
# Serve and build helpers for an MkDocs site in the current directory.
###############################################################################

# @group: MkDocs
# @keys: mkdocs,docs

alias mkdocs-serve='mkdocs serve'
alias mkdocs-build='mkdocs build --strict'
alias mkdocs-lan='mkdocs serve --dev-addr 0.0.0.0:8000'

# ===================================== EOF ====================================
