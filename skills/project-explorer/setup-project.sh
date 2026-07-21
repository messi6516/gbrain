#!/usr/bin/env bash
set -euo pipefail

#====================================================================
# project-explorer: setup-project.sh
# Companion script for the project-explorer skill (Phase 1).
# Onboards any open-source project into gbrain as a new source.
#
# Usage:
#   ./setup-project.sh /path/to/project [--slug <slug>] [--embed]
#
# If --slug is omitted, the basename of the project directory is used.
# If --embed is passed, embeddings are generated immediately (off by
# default -- run 'gbrain embed --stale --source <slug>' separately if
# you prefer to control timing).
#
# Prerequisites: gbrain CLI installed, gbrain init completed.
#====================================================================

PROJECT_DIR=""
PROJECT_SLUG=""
DO_EMBED=false

usage() {
  cat <<EOF
Usage: $(basename "$0") <project-dir> [--slug <slug>] [--embed]

Onboards a project into gbrain as a new source and creates initial
analysis pages.

Arguments:
  <project-dir>   Path to the project root directory (required)
  --slug <slug>   gbrain source slug (default: basename of project dir)
  --embed         Run embedding immediately after import (default: off)
  --help          Show this help message

Examples:
  ./setup-project.sh ~/code/my-project
  ./setup-project.sh ~/code/my-project --slug my-org-my-project --embed

Steps performed:
  1. Detect project metadata (language, build system, package manager)
  2. Create gbrain source: gbrain sources add <slug> --path <dir>
  3. Import source code, docs, and config files
  4. Create _project/overview page with metadata
  5. Create _project/architecture page as placeholder for Phase 2
  6. Link overview and architecture pages
  7. Run gbrain doctor to verify health
EOF
  exit 0
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)
      PROJECT_SLUG="$2"
      shift 2
      ;;
    --embed)
      DO_EMBED=true
      shift
      ;;
    --help)
      usage
      ;;
    -*)
      echo "Error: unknown flag $1"
      usage
      ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$1"
      else
        echo "Error: unexpected argument $1"
        usage
      fi
      shift
      ;;
  esac
done

# --- Validate ---
if [[ -z "$PROJECT_DIR" ]]; then
  echo "Error: <project-dir> is required"
  usage
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: directory not found: $PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ -z "$PROJECT_SLUG" ]]; then
  PROJECT_SLUG="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g; s/^-//; s/-$//')"
fi

# --- Check gbrain ---
if ! command -v gbrain &>/dev/null; then
  echo "Error: gbrain CLI not found. Install it first:"
  echo "  curl -fsSL https://bun.sh/install | bash"
  echo "  export PATH=\"\$HOME/.bun/bin:\$PATH\""
  echo "  bun install -g github:garrytan/gbrain"
  exit 1
fi

echo "==> Onboarding project into gbrain"
echo "    Project: $PROJECT_DIR"
echo "    Source:  $PROJECT_SLUG"
echo ""

# --- Step 1: Detect project metadata ---
echo "==> [1/8] Detecting project metadata..."
LANGUAGE="unknown"
BUILD_SYSTEM="unknown"
PKG_MANAGER="unknown"
ENTRY_POINTS=""

if [[ -f "$PROJECT_DIR/package.json" ]]; then
  LANGUAGE="JavaScript/TypeScript"
  BUILD_SYSTEM="$(node -e "try{const p=require('$PROJECT_DIR/package.json');console.log(p.scripts?.build?'has-build-script':'no-build-script')}catch(e){console.log('parse-error')}" 2>/dev/null || echo "unknown")"
  if [[ -f "$PROJECT_DIR/bun.lock" ]]; then
    PKG_MANAGER="bun"
  elif [[ -f "$PROJECT_DIR/yarn.lock" ]]; then
    PKG_MANAGER="yarn"
  elif [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]]; then
    PKG_MANAGER="pnpm"
  elif [[ -f "$PROJECT_DIR/package-lock.json" ]]; then
    PKG_MANAGER="npm"
  fi
  if [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
    LANGUAGE="TypeScript"
  fi
elif [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
  LANGUAGE="Python"
  PKG_MANAGER="$(grep -q 'poetry' "$PROJECT_DIR/pyproject.toml" 2>/dev/null && echo 'poetry' || echo 'pip')"
elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
  LANGUAGE="Rust"
  PKG_MANAGER="cargo"
elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
  LANGUAGE="Go"
  PKG_MANAGER="go modules"
elif [[ -f "$PROJECT_DIR/CMakeLists.txt" ]]; then
  LANGUAGE="C/C++"
  BUILD_SYSTEM="cmake"
elif [[ -f "$PROJECT_DIR/Makefile" ]] || [[ -f "$PROJECT_DIR/makefile" ]]; then
  BUILD_SYSTEM="make"
fi

echo "    Language:    $LANGUAGE"
echo "    Build:       $BUILD_SYSTEM"
echo "    Package:     $PKG_MANAGER"

# --- Step 2: Create gbrain source ---
echo "==> [2/8] Creating gbrain source '$PROJECT_SLUG'..."
if gbrain sources current --source "$PROJECT_SLUG" &>/dev/null; then
  echo "    Source '$PROJECT_SLUG' already exists, skipping creation."
else
  gbrain sources add "$PROJECT_SLUG" --path "$PROJECT_DIR"
  echo "    Source created."
fi

# --- Step 3: Import source code ---
echo "==> [3/8] Importing source code (no embed)..."

do_import() {
  local label="$1"
  shift
  echo "    Importing $label..."
  gbrain import "$PROJECT_DIR" --source "$PROJECT_SLUG" --no-embed "$@" 2>/dev/null || true
}

# Prioritize source directories
for srcdir in src lib app cmd internal core; do
  if [[ -d "$PROJECT_DIR/$srcdir" ]]; then
    do_import "$srcdir/" --include "$srcdir/**"
  fi
done

# Import top-level source files
do_import "root source files" --include '*.{py,js,ts,jsx,tsx,go,rs,rb,php,java,kt,scala,clj,ex,exs}'

# Import docs
if [[ -d "$PROJECT_DIR/docs" ]] || [[ -d "$PROJECT_DIR/documentation" ]]; then
  do_import "documentation"
fi

# Import config files
do_import "config files" --include '*.{json,toml,yaml,yml,xml,ini,cfg,conf}'

echo "    Import complete."

# --- Step 4: Embed (optional) ---
if $DO_EMBED; then
  echo "==> [4/8] Generating embeddings..."
  gbrain embed --stale --source "$PROJECT_SLUG"
else
  echo "==> [4/8] Embedding skipped (pass --embed to enable)."
  echo "    Run later: gbrain embed --stale --source $PROJECT_SLUG"
fi

# --- Step 5: Count imported files ---
echo "==> [5/8] Checking import status..."
FILE_COUNT=$(gbrain search --source "$PROJECT_SLUG" "" --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('results',[])))" 2>/dev/null || echo "unknown")
echo "    Chunks imported: $FILE_COUNT"

# --- Step 6: Create project overview page ---
echo "==> [6/8] Creating project overview page..."
CURRENT_DATE=$(date +%Y-%m-%d)
OVERVIEW_BODY=$(cat <<EOB
---
type: project
slug: $PROJECT_SLUG
language: $LANGUAGE
build_system: $BUILD_SYSTEM
package_manager: $PKG_MANAGER
onboarded_at: $CURRENT_DATE
source_dir: $PROJECT_DIR
---

# Project Overview: $PROJECT_SLUG

Onboarded into gbrain on $CURRENT_DATE.

## Metadata

- Language: $LANGUAGE
- Build system: $BUILD_SYSTEM
- Package manager: $PKG_MANAGER
- Project directory: $PROJECT_DIR

## Quick start

Query the codebase:
\`\`\`bash
gbrain query --source $PROJECT_SLUG "what does this project do"
gbrain query --source $PROJECT_SLUG "core domain entities"
\`\`\`

Explore architecture (requires Phase 2 of project-explorer skill):
\`\`\`bash
gbrain get_page --source $PROJECT_SLUG --slug _project/architecture
gbrain traverse_graph _project/overview --source $PROJECT_SLUG --depth 3
\`\`\`
EOB
)

gbrain put_page --source "$PROJECT_SLUG" --slug _project/overview --body "$OVERVIEW_BODY" 2>/dev/null || echo "    (page may already exist, update skipped)"

# --- Step 7: Create architecture placeholder ---
echo "==> [7/8] Creating architecture overview placeholder..."
ARCH_BODY=$(cat <<EOB
---
type: architecture-overview
project: $PROJECT_SLUG
---

# Architecture Overview: $PROJECT_SLUG

> This page is populated by the project-explorer skill Phase 2 (Architecture Discovery).
> Run \`gbrain think --source $PROJECT_SLUG "map the architecture: entry points, modules, dependencies"\`
> to seed this page.

## To populate

1. Identify entry points (main, CLI, server startup)
2. Map top-level module boundaries
3. Document inter-module dependencies
4. Identify external system boundaries

## Quick links

- [Project overview](_project/overview)
- Module map: (run Phase 2)
EOB
)

gbrain put_page --source "$PROJECT_SLUG" --slug _project/architecture --body "$ARCH_BODY" 2>/dev/null || echo "    (page may already exist, update skipped)"

# --- Step 8: Link overview pages ---
echo "==> [8/8] Linking overview pages..."
gbrain add_link --source "$PROJECT_SLUG" --from _project/overview --to _project/architecture --type contains 2>/dev/null || true

# --- Final health check ---
echo ""
echo "==> Running gbrain doctor for source $PROJECT_SLUG..."
gbrain doctor --source "$PROJECT_SLUG" --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    checks=d.get('checks',d.get('results',[]))
    passed=sum(1 for c in checks if c.get('status','') in ('ok','passed'))
    failed=sum(1 for c in checks if c.get('status','') in ('fail','error'))
    print(f'    Health: {passed} passed, {failed} failed (if any)')
except: print('    (doctor output available)')
" 2>/dev/null || echo "    (doctor check complete)"

echo ""
echo "============================================"
echo "  Project '$PROJECT_SLUG' onboarded successfully!"
echo "============================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Start exploring:"
echo "     gbrain query --source $PROJECT_SLUG \"what does this project do\""
echo ""
echo "  2. Run Phase 2 (Architecture Discovery):"
echo "     gbrain think --source $PROJECT_SLUG \\"
echo "       \"map the architecture: entry points, modules, dependencies\""
echo "     gbrain get_page --source $PROJECT_SLUG --slug _project/architecture"
echo ""
echo "  3. Run Phase 3 (Domain Model Extraction):"
echo "     gbrain think --source $PROJECT_SLUG \\"
echo "       \"what are the core domain entities and their relationships\""
echo ""
echo "  4. Read the full skill:"
echo "     cat skills/project-explorer/SKILL.md"
echo ""
echo "  5. Enrich over time: ask questions and gbrain accumulates:"
echo "     gbrain query --source $PROJECT_SLUG \"how does the payment flow work\""
echo ""
echo "  6. When ready to refactor, create a target source:"
echo "     gbrain sources add $PROJECT_SLUG-target --path <project-dir>"
echo "     # Then read Phase 6 of the skill"
echo ""
echo "To verify the source: gbrain sources current --source $PROJECT_SLUG"
echo "To verify pages:  gbrain search --source $PROJECT_SLUG ''"
echo "============================================"
