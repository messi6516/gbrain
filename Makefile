# GBrain Makefile
# PostgreSQL: trading@localhost:5432/gbrain
# Usage: make install | make update | make restart

DB_URL := postgresql://trading:82790086@localhost:5432/gbrain
GBRAIN_BIN := $(shell which gbrain 2>/dev/null || echo bunx gbrain)
PID_FILE := /tmp/gbrain-serve.pid

# Auto-detect embedding API keys; skip embedding init if none are set
HAS_EMBED_KEY := $(shell \
	if [ -n "$$OPENAI_API_KEY" ] || [ -n "$$ZEROENTROPY_API_KEY" ] || [ -n "$$VOYAGE_API_KEY" ]; then \
		echo 1; else echo 0; fi)

.PHONY: install update restart status doctor serve serve-http stop help embed-config

##@ Main targets

# Install gbrain and initialize with the PostgreSQL database
install:
	@echo "==> Checking prerequisites..."
	@command -v bun >/dev/null 2>&1 || { echo "Error: bun is not installed. Install it from https://bun.sh"; exit 1; }
	@echo "==> Installing gbrain globally..."
	bun install -g github:garrytan/gbrain
	@echo "==> Initializing gbrain with PostgreSQL..."
	@if [ "$(HAS_EMBED_KEY)" = "1" ]; then \
		echo "  Embedding API key detected, initializing with full setup..."; \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain init --non-interactive; \
	else \
		echo "  No embedding API key found — deferring embedding setup."; \
		echo "  You can configure it later with:  make embed-config"; \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain init --non-interactive --no-embedding; \
	fi
	@echo "==> Running health check..."
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain doctor || true
	@echo ""
	@echo "✓ Install complete. Available commands:"
	@echo "  make serve        - Start gbrain MCP (stdio)"
	@echo "  make serve-http   - Start gbrain HTTP server"
	@echo "  make status       - Check if gbrain is running"
	@echo "  make doctor       - Run health diagnostics"
	@if [ "$(HAS_EMBED_KEY)" = "0" ]; then \
		echo ""; \
		echo "⚠  Embedding not configured yet. To enable search/semantic features:"; \
		echo "  export OPENAI_API_KEY=sk-...   # or ZEROENTROPY_API_KEY / VOYAGE_API_KEY"; \
		echo "  make embed-config              # then run this"; \
	fi

# Update gbrain to the latest version
update:
	@echo "==> Updating gbrain..."
	bun install -g github:garrytan/gbrain
	@echo "==> Running pending migrations..."
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain upgrade --force-schema --yes || \
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain init --migrate-only
	@echo "==> Post-upgrade health check..."
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain doctor
	@echo "✓ Update complete. Run 'make restart' if serve is running."

# Restart gbrain serve (stop + start)
restart: stop serve
	@echo "✓ Restart complete."

##@ Service control

# Start gbrain MCP stdio server in background (for Claude Code / Codex / Cursor)
serve:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "gbrain serve is already running (PID $$(cat $(PID_FILE)))"; \
	else \
		echo "==> Starting gbrain serve (stdio MCP)..."; \
		GBRAIN_DATABASE_URL=$(DB_URL) nohup gbrain serve > /tmp/gbrain-serve.log 2>&1 & \
		echo $$! > $(PID_FILE); \
		echo "✓ gbrain serve started (PID $$(cat $(PID_FILE)))"; \
		echo "  Logs: tail -f /tmp/gbrain-serve.log"; \
	fi

# Start gbrain HTTP MCP server (for remote clients)
serve-http:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "gbrain serve is already running (PID $$(cat $(PID_FILE))). Stop it first: make stop"; \
		exit 1; \
	fi
	@echo "==> Starting gbrain serve --http on port 3131..."
	GBRAIN_DATABASE_URL=$(DB_URL) nohup gbrain serve --http --port 3131 > /tmp/gbrain-serve.log 2>&1 & \
	echo $$! > $(PID_FILE); \
	echo "✓ gbrain HTTP server started (PID $$(cat $(PID_FILE)))"; \
	echo "  URL:     http://localhost:3131"; \
	echo "  Admin:   http://localhost:3131/admin"; \
	echo "  MCP:     http://localhost:3131/mcp"; \
	echo "  Logs:    tail -f /tmp/gbrain-serve.log"

# Stop gbrain serve
stop:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "==> Stopping gbrain serve (PID $$(cat $(PID_FILE)))..."; \
		kill $$(cat $(PID_FILE)) 2>/dev/null || true; \
		sleep 1; \
		if kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
			echo "Process didn't stop, force killing..."; \
			kill -9 $$(cat $(PID_FILE)) 2>/dev/null || true; \
		fi; \
		rm -f $(PID_FILE); \
		echo "✓ Stopped."; \
	else \
		echo "No gbrain serve process found."; \
		rm -f $(PID_FILE); \
	fi

##@ Status & diagnostics

# Show gbrain status (process + health)
status:
	@echo "=== Process ==="
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "  gbrain serve:  running (PID $$(cat $(PID_FILE)))"; \
	else \
		echo "  gbrain serve:  not running"; \
	fi
	@echo ""
	@echo "=== Database ==="
	@GBRAIN_DATABASE_URL=$(DB_URL) gbrain doctor 2>&1 || true

# Run health diagnostics
doctor:
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain doctor

# Show configured models
models:
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain models

# Configure embedding after a --no-embedding install
embed-config:
	@echo "==> Configuring embedding..."
	@if [ -z "$$OPENAI_API_KEY" ] && [ -z "$$ZEROENTROPY_API_KEY" ] && [ -z "$$VOYAGE_API_KEY" ]; then \
		echo "Error: No embedding API key found in environment."; \
		echo "Set one of:"; \
		echo "  export OPENAI_API_KEY=sk-..."; \
		echo "  export ZEROENTROPY_API_KEY=ze-..."; \
		echo "  export VOYAGE_API_KEY=pa-..."; \
		echo "Then re-run: make embed-config"; \
		exit 1; \
	fi
	@if [ -n "$$OPENAI_API_KEY" ]; then \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_model openai:text-embedding-3-large; \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_dimensions 1536; \
	elif [ -n "$$VOYAGE_API_KEY" ]; then \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_model voyage:voyage-3-large; \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_dimensions 1024; \
	elif [ -n "$$ZEROENTROPY_API_KEY" ]; then \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_model zeroentropyai:zembed-1; \
		GBRAIN_DATABASE_URL=$(DB_URL) gbrain config set embedding_dimensions 2560; \
	fi
	@echo "==> Testing embedding..."
	GBRAIN_DATABASE_URL=$(DB_URL) gbrain models doctor
	@echo "✓ Embedding configured successfully."

##@ Help

help:
	@echo "GBrain Makefile"
	@echo "  PostgreSQL: trading@localhost:5432/gbrain"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  install       Install gbrain + init with PostgreSQL"
	@echo "  update        Update gbrain to latest version"
	@echo "  restart       Restart gbrain serve (stop + start)"
	@echo "  serve         Start gbrain MCP stdio server"
	@echo "  serve-http    Start gbrain HTTP server (port 3131)"
	@echo "  stop          Stop gbrain serve"
	@echo "  status        Show process status + health check"
	@echo "  doctor        Run health diagnostics"
	@echo "  models        List configured AI models"
	@echo "  embed-config  Configure embedding provider (after --no-embedding install)"
