.PHONY: install lint format typecheck clean all

# Install dependencies
install:
	pip install --upgrade pip && \
	pip install -r requirements.txt

# Run ruff linter
lint:
	ruff check .

# Run ruff formatter
format:
	ruff format .

# Run mypy type checker
typecheck:
	mypy .

# Clean up cache files
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true

# Run all checks
all: lint typecheck