#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Error: Godot binary not found or not executable at: $GODOT_BIN"
  echo "Set GODOT_BIN to override, e.g.:"
  echo "  GODOT_BIN=/path/to/Godot bash tools/run_ui_theme_pipeline.sh"
  exit 1
fi

run_step() {
  local title="$1"
  shift
  echo
  echo "==> $title"
  "$@"
}

run_step "Sync main theme from UI tokens" \
  "$GODOT_BIN" --headless --path "$PROJECT_ROOT" -s tools/run_theme_token_sync.gd

run_step "Run token-to-theme sync test" \
  "$GODOT_BIN" --headless --path "$PROJECT_ROOT" \
  -s addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/test_theme_token_sync.gd -gexit

run_step "Run .tres symbol guard test" \
  "$GODOT_BIN" --headless --path "$PROJECT_ROOT" \
  -s addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/test_tres_symbol_guards.gd -gexit

echo
echo "UI theme pipeline complete."
