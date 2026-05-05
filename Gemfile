# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in core.gemspec.
# This pulls in rails, pg, sidekiq, devise, searchkick, etc.
gemspec

# --- Engine-specific development gems ---
# (None for now, they are all in the gemspec as development dependencies)

# --- Server-level dependencies ---
# These are kept in the Gemfile as they are usually environment-specific
gem "puma"
gem "pg"
gem "propshaft"
gem "jbuilder"
gem "bootsnap", require: false

# Shared tools that we want available in all environments
# gem "debug", ">= 1.0.0"
