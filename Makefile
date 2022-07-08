export PYTHONDONTWRITEBYTECODE=1

.PHONY=help

help:  ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

clean:  ## Remove cache files
	@find . -name "*.pyc" | xargs rm -rf
	@find . -name "*.pyo" | xargs rm -rf
	@find . -name "__pycache__" -type d | xargs rm -rf


###
# Dependencies section
###
_base-pip:
	@pip install -U pip poetry wheel

system-dependencies:
	@sudo apt-get update -y && sudo apt-get install -y libpq-dev

dev-dependencies: _base-pip  ## Install development dependencies
	@poetry install

export-requirements: _base-pip
	@poetry export --without-hashes --dev -f requirements.txt > requirements.txt

ci-dependencies:
	@pip install -r requirements.txt

dependencies: _base-pip  ## Install dependencies
	@poetry install --no-dev

outdated:  ## Show outdated packages
	@poetry show --outdated


###
# Tests section
###
test: clean  ## Run tests
	@pytest --asyncio-mode=auto tests/

test-coverage: clean  ## Run tests with coverage output
	@pytest --asyncio-mode=auto tests/ --cov app/ --cov-report term-missing --cov-report xml

test-matching: clean  ## Run tests by match ex: make test-matching k=name_of_test
	@pytest --asyncio-mode=auto -k $(k) tests/

test-security: clean  ## Run security tests with bandit and safety
	@python -m bandit -r app -x "test"
	@python -m safety check


###
# Migrations DB section
###
migrations:  ## Create named migrations file. Ex: make migrations name=<migration_name>
	@alembic revision --autogenerate --message $(name)

migrate:  ## Apply local migrations
	@alembic upgrade head

history:  ## migrations history
	@alembic history

branches: ## migrations branch point
	@alembic branches --verbose

merge: ## Create named migrations file from multiplous heads. Ex: make merge m=<migration_name>
	@alembic merge heads -m ${m}

pre-commit-install:  ## Install pre-commit hooks
	@pre-commit install

pre-commit-uninstall:  ## Uninstall pre-commit hooks
	@pre-commit uninstall


###
# Run local section
###
copy-envs:  ## Copy `.env.example` to `.env`
	@cp -n .env.example .env

init: dev-dependencies pre-commit-install copy-envs ## Initialize project

run-local:  ## Run server
	@python -m app
