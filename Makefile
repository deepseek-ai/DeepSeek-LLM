print-%  : ; @echo $* = $($*)
PROJECT_NAME   = DeepSeek-LLM
COPYRIGHT      = "DeepSeek."
PROJECT_PATH   = evaluation
SHELL          = /bin/bash
SOURCE_FOLDERS = evaluation
PYTHON_FILES   = $(shell find $(SOURCE_FOLDERS) -type f -name "*.py" -o -name "*.pyi")
COMMIT_HASH    = $(shell git log -1 --format=%h)
PATH           := $(HOME)/go/bin:$(PATH)
PYTHON         ?= $(shell command -v python3 || command -v python)
PYTESTOPTS     ?=

.PHONY: default
default: install

# Tools Installation

check_pip_install = $(PYTHON) -m pip show $(1) &>/dev/null || (cd && $(PYTHON) -m pip install $(1) --upgrade)
check_pip_install_extra = $(PYTHON) -m pip show $(1) &>/dev/null || (cd && $(PYTHON) -m pip install $(2) --upgrade)

pylint-install:
	$(call check_pip_install_extra,pylint,pylint[spelling])
	$(call check_pip_install,pyenchant)

flake8-install:
	$(call check_pip_install,flake8)
	$(call check_pip_install,flake8-bugbear)
	$(call check_pip_install,flake8-comprehensions)
	$(call check_pip_install,flake8-docstrings)
	$(call check_pip_install,flake8-pyi)
	$(call check_pip_install,flake8-simplify)

py-format-install:
	$(call check_pip_install,isort)
	$(call check_pip_install_extra,black,black[jupyter])

ruff-install:
	$(call check_pip_install,ruff)

mypy-install:
	$(call check_pip_install,mypy)

pre-commit-install:
	$(call check_pip_install,pre-commit)
	$(PYTHON) -m pre_commit install --install-hooks

go-install:
	# requires go >= 1.16
	command -v go || (sudo apt-get install -y golang && sudo ln -sf /usr/lib/go/bin/go /usr/bin/go)

addlicense-install: go-install
	command -v addlicense || go install github.com/google/addlicense@latest

addlicense: addlicense-install
	addlicense -c $(COPYRIGHT) -ignore tests/coverage.xml -l mit -y 2023-$(shell date +"%Y") -check $(SOURCE_FOLDERS)

# Python linters

pylint: pylint-install
	$(PYTHON) -m pylint $(PROJECT_PATH)

flake8: flake8-install
	$(PYTHON) -m flake8 --count --show-source --statistics

py-format: py-format-install
	$(PYTHON) -m isort --project $(PROJECT_PATH) --check $(PYTHON_FILES) && \
	$(PYTHON) -m black --check $(PYTHON_FILES)

ruff: ruff-install
	$(PYTHON) -m ruff check .

ruff-fix: ruff-install
	$(PYTHON) -m ruff check . --fix --exit-non-zero-on-fix

mypy: mypy-install
	$(PYTHON) -m mypy $(PROJECT_PATH) --install-types --non-interactive

pre-commit: pre-commit-install
	$(PYTHON) -m pre_commit run --all-files

# Utility functions

lint: ruff flake8 py-format mypy pylint addlicense

format: py-format-install ruff-install addlicense-install
	$(PYTHON) -m isort --project $(PROJECT_PATH) $(PYTHON_FILES)
	$(PYTHON) -m black $(PYTHON_FILES)
	$(PYTHON) -m ruff check . --fix --exit-zero
	addlicense -c $(COPYRIGHT) -ignore tests/coverage.xml -l mit -y 2023-$(shell date +"%Y") $(SOURCE_FOLDERS)

clean-py:
	find . -type f -name  '*.py[co]' -delete
	find . -depth -type d -name "__pycache__" -exec rm -r "{}" +
	find . -depth -type d -name ".ruff_cache" -exec rm -r "{}" +
	find . -depth -type d -name ".mypy_cache" -exec rm -r "{}" +

clean: clean-py
