# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby on Rails application designed to help development teams tackle tech debt more efficiently by identifying low-complexity bug tickets in their JIRA backlog and assigning them to an AI engineer (Devin) for automated resolution.
- Rails 8.0.2 
- SQLite (database)

## Essential Commands

### Development
- **Run application**: `./rails server`
- **Run tests**: `./rails test`
- **Generate migration**: `./rails generate migration MigrationName`

## Architecture

### Database Layer
- Generate database migrations for schema changes

### UI Layer
- Use Tailwind classes for all css styling

### Testing
- Do not generate system tests
