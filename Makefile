# GBrain Makefile
# Usage: make install | make update | make restart
#
# Connection: trading@localhost:5432/gbrain
# Embedding:  ZeroEntropy (zembed-1, 1280d)
# Chat:       openai:deepseek-v4-flash via https://opencode.ai/zen/go/v1
#
# Secrets are loaded from .env file if present (keeps keys out of shell history).
# Run `make env` to scaffold one.

DB_URL       := postgresql://trading:82790086@localhost:5432/gbrain
PID_FILE     := /tmp/gbrain-serve.pid
HTTP_PORT    := 3131

# ---- secrets (override via .env or env vars) ----
ZE_KEY       ?= ze_qtVb0E5m60m4V1re
OPENAI_KEY   ?= sk-6YHNlUzCTdufbUc9nrnnXfKdfFs0Yb3j1Gl9W07e4Z8ozDdPdqy1bJrNegt6L02j
OPENAI_BASE  ?= https://opencode.ai/zen/go/v1

# ---- embedding ----
EMBED_PROVIDER := zeroentropyai:zembed-1
EMBED_DIMS     := 1280

# ---- chat / expansion ----
CHAT_MODEL      := openai:deepseek-v4-flash
EXPANSION_MODEL := openai:deepseek-v4-flash

# runtime env block passed to every gbrain invocation
GBRAIN_ENV  := GBRAIN_DATABASE_URL=$(DB_URL)
GBRAIN_ENV  += ZEROENTROPY_API_KEY=$(ZE_KEY)
GBRAIN_ENV  += OPENAI_API_KEY=$(OPENAI_KEY)
GBRAIN_ENV  += OPENAI_BASE_URL=$(OPENAI_BASE)

.PHONY: build deploy install restart serve serve-http stop status doctor models embed-config env help sync

##@ Build

# Compile local source → bin/gbrain
build:
	@echo "==> Building gbrain from local source..."
	bash scripts/build-schema.sh
	bun build --compile --outfile bin/gbrain src/cli.ts
	@echo "✓ Built bin/gbrain ($(shell bin/gbrain --version 2>/dev/null))"

# Build + replace global binary + restart serve (daily dev loop)
deploy: build
	@echo "==> Deploying to PATH..."
	cp bin/gbrain $(shell which gbrain)
	@echo "==> Restarting gbrain serve..."
	$(MAKE) stop 2>/dev/null || true
	sleep 1
	$(MAKE) serve
	@echo "✓ Deployed and restarted."

# First-time setup: deploy + init DB + configure models
install: deploy
	@echo "==> Initializing gbrain (embedding: $(EMBED_PROVIDER))..."
	$(GBRAIN_ENV) gbrain init --non-interactive \
		--url $(DB_URL) \
		--embedding-model $(EMBED_PROVIDER) \
		--embedding-dimensions $(EMBED_DIMS) \
		--chat-model $(CHAT_MODEL) \
		--expansion-model $(EXPANSION_MODEL)
	@echo "==> Setting custom OpenAI base URL..."
	$(GBRAIN_ENV) gbrain config set provider_base_urls.openai $(OPENAI_BASE)
	@echo "==> Running health check..."
	$(GBRAIN_ENV) gbrain doctor || true
	@echo ""
	@echo "✓ GBrain installed and running."

##@ Service

##@ Service

# Start stdio MCP (local agents: Claude Code / Codex / Cursor)
serve:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "gbrain serve already running (PID $$(cat $(PID_FILE)))"; \
	else \
		echo "==> Starting gbrain serve (stdio MCP)..."; \
		$(GBRAIN_ENV) nohup gbrain serve > /tmp/gbrain-serve.log 2>&1 & \
		echo $$! > $(PID_FILE); \
		echo "✓ Started (PID $$(cat $(PID_FILE)))"; \
		echo "  Logs: tail -f /tmp/gbrain-serve.log"; \
	fi

# Start HTTP MCP + admin dashboard
serve-http:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "Server already running (PID $$(cat $(PID_FILE))). Run: make stop"; \
		exit 1; \
	fi
	@echo "==> Starting gbrain serve --http on :$(HTTP_PORT)..."
	$(GBRAIN_ENV) nohup gbrain serve --http --port $(HTTP_PORT) > /tmp/gbrain-serve.log 2>&1 & \
	echo $$! > $(PID_FILE); \
	echo "✓ HTTP server started (PID $$(cat $(PID_FILE)))"; \
	echo "  MCP:      http://localhost:$(HTTP_PORT)/mcp"; \
	echo "  Admin:    http://localhost:$(HTTP_PORT)/admin"; \
	echo "  Logs:     tail -f /tmp/gbrain-serve.log"

# Stop the server
stop:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "==> Stopping gbrain serve (PID $$(cat $(PID_FILE)))..."; \
		kill $$(cat $(PID_FILE)) 2>/dev/null || true; \
		sleep 1; \
		kill -0 $$(cat $(PID_FILE)) 2>/dev/null && kill -9 $$(cat $(PID_FILE)) 2>/dev/null || true; \
		rm -f $(PID_FILE); \
		echo "✓ Stopped."; \
	else \
		echo "No running gbrain serve process."; \
		rm -f $(PID_FILE); \
	fi

##@ Diagnostics

# One-line process + db health
status:
	@echo "=== Process ==="
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "  gbrain serve:  running (PID $$(cat $(PID_FILE)))"; \
	else \
		echo "  gbrain serve:  not running"; \
	fi
	@echo "=== Database ==="
	@$(GBRAIN_ENV) gbrain doctor 2>&1 || true

doctor:
	$(GBRAIN_ENV) gbrain doctor

models:
	$(GBRAIN_ENV) gbrain models

models-doctor:
	$(GBRAIN_ENV) gbrain models doctor

##@ Setup helpers

# Validate embedding + chat models with a 1-token probe
embed-config:
	@echo "==> Probing embedding model ($(EMBED_PROVIDER))..."
	$(GBRAIN_ENV) gbrain models doctor
	@echo "✓ OK."

# Scaffold a .env file with the embedded secrets
env:
	@test -f .env && { echo "Error: .env already exists. Delete it first."; exit 1; } || true
	@echo "ZEROENTROPY_API_KEY=$(ZE_KEY)"  > .env
	@echo "OPENAI_API_KEY=$(OPENAI_KEY)"   >> .env
	@echo "OPENAI_BASE_URL=$(OPENAI_BASE)" >> .env
	@echo "✓ .env written (git-ignored by default)."

##@ Sync

# Sync fork with upstream: fetch, rebase, force-push to origin/dev-chinese
sync:
	@echo "==> Fetching upstream..."
	git fetch upstream
	@echo "==> Rebasing dev-chinese onto upstream/master..."
	@if ! git diff --quiet HEAD; then \
		echo "Error: working tree has uncommitted changes. Commit or stash them first."; \
		exit 1; \
	fi
	git rebase upstream/master
	@echo "==> Force-pushing to origin/dev-chinese..."
	git push origin dev-chinese --force-with-lease
	@echo "✓ dev-chinese is now up to date with upstream/master"


##@ Help

help:
	@echo "GBrain Makefile"
	@echo "  PostgreSQL: trading@localhost:5432/gbrain"
	@echo "  Embedding:  $(EMBED_PROVIDER) ($(EMBED_DIMS)d)"
	@echo "  Chat:       $(CHAT_MODEL)"
	@echo ""
	@echo "  make build          Compile local source -> bin/gbrain"
	@echo "  make deploy         Build + replace + restart (daily dev)"
	@echo "  make install        Deploy + init DB (first-time setup)"
	@echo "  make serve          Start stdio MCP"
	@echo "  make serve-http     Start HTTP MCP (port $(HTTP_PORT))"
	@echo "  make stop           Stop server"
	@echo "  make status         Process + DB health"
	@echo "  make doctor         Full health diagnostics"
	@echo "  make models         List configured models"
	@echo "  make models-doctor  1-token probe per model"
	@echo "  make env            Scaffold .env file"
	@echo "  make sync           Rebase fork from upstream & push to origin"

