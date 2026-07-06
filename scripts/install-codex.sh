#!/usr/bin/env bash
#
# install-codex.sh — wire the super-puper-powers skills into OpenAI Codex.
#
# Codex discovers "personal skills" under ~/.agents/skills/<name>/SKILL.md. This script
# symlinks each skill directory from this repo into that location, so the repo stays the
# single source of truth (edit here, Codex sees it after a restart).
#
# Usage:
#   ./scripts/install-codex.sh            # install/refresh symlinks
#   ./scripts/install-codex.sh --uninstall # remove the symlinks this script created
#
# After installing, restart Codex so it picks up the skills. Codex has no SessionStart hook,
# so the orchestrator is not auto-injected — start the pipeline by invoking
# super-puper-powers:using-super-puper-powers, or a phase skill directly (they carry
# standalone triggers). See README, "Установка в Codex" / "Install under Codex".

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="${REPO_ROOT}/skills"
DEST_DIR="${HOME}/.agents/skills"

if [ ! -d "$SKILLS_SRC" ]; then
    echo "error: no skills/ directory at ${SKILLS_SRC}" >&2
    exit 1
fi

uninstall() {
    local removed=0
    for src in "$SKILLS_SRC"/*/; do
        name="$(basename "$src")"
        link="${DEST_DIR}/${name}"
        # Only remove a symlink that points back into THIS repo — never touch real dirs
        # or links owned by something else.
        if [ -L "$link" ] && [ "$(readlink "$link")" = "${src%/}" ]; then
            rm "$link"
            removed=$((removed + 1))
        fi
    done
    echo "Removed ${removed} super-puper-powers skill symlink(s) from ${DEST_DIR}."
    echo "Restart Codex to apply."
}

install() {
    mkdir -p "$DEST_DIR"
    local linked=0 skipped=0
    for src in "$SKILLS_SRC"/*/; do
        name="$(basename "$src")"
        link="${DEST_DIR}/${name}"
        target="${src%/}"
        if [ -e "$link" ] && [ ! -L "$link" ]; then
            echo "  skip ${name}: a real file/dir already exists at ${link} (not overwriting)" >&2
            skipped=$((skipped + 1))
            continue
        fi
        ln -sfn "$target" "$link"
        linked=$((linked + 1))
    done
    echo "Linked ${linked} skill(s) into ${DEST_DIR}."
    [ "$skipped" -gt 0 ] && echo "Skipped ${skipped} (a non-symlink already existed — resolve manually)."
    echo ""
    echo "Restart Codex so it picks up the skills. Codex has no SessionStart hook, so start the"
    echo "pipeline explicitly: invoke super-puper-powers:using-super-puper-powers, or a phase skill"
    echo "by name. Multi-agent config and env detection: skills/using-super-puper-powers/references/codex-tools.md"
}

case "${1:-install}" in
    --uninstall|-u|uninstall) uninstall ;;
    install|"") install ;;
    *) echo "usage: $0 [--uninstall]" >&2; exit 1 ;;
esac
