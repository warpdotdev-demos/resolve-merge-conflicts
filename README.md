# Resolve Merge Conflicts — Warp Oz Skill

A [Warp](https://www.warp.dev) skill that teaches Oz (Warp's AI agent) how to resolve Git merge conflicts efficiently. Instead of reading entire conflicted files into context, the skill uses a compact extraction script that shows only the conflict hunks, surrounding context, and a unified diff between the two sides.

## What's included

```
.agents/skills/resolve-merge-conflicts/
├── SKILL.md                                # Skill definition (workflow + commands)
└── scripts/
    └── extract_conflict_context.py         # Python script for compact conflict extraction
```

## Installation

Copy the `.agents/skills/resolve-merge-conflicts/` directory into your project:

```bash
# From your project root
mkdir -p .agents/skills
cp -r path/to/resolve-merge-conflicts/.agents/skills/resolve-merge-conflicts .agents/skills/
```

Or clone this repo and symlink:

```bash
git clone https://github.com/warpdotdev-demos/resolve-merge-conflicts.git
ln -s "$(pwd)/resolve-merge-conflicts/.agents/skills/resolve-merge-conflicts" \
  /path/to/your-project/.agents/skills/resolve-merge-conflicts
```

Once the skill is in your project's `.agents/skills/` directory, Oz will automatically pick it up when it encounters merge conflicts.

## How it works

When Oz encounters merge conflicts (after a merge, rebase, cherry-pick, or stash pop), the skill guides it through a structured workflow:

1. **Summary** — Run the extraction script with no arguments to get a compact overview of all conflicted files, their conflict types, and hunk counts.

2. **Drill into one file** — Use `--file path/to/file` to see only the conflict hunks with surrounding context and a unified diff between `ours` and `theirs`.

3. **Resolve** — Take one side with `git checkout --ours/--theirs`, or edit the file directly to remove conflict markers.

4. **Validate** — Confirm no unmerged paths or leftover markers remain, then run tests/linters for the touched area.

## Standalone usage

The Python script works independently of Warp — you can run it directly in any Git repo with merge conflicts:

```bash
# Summary of all conflicted files
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py

# Detailed view for one file
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --file src/app.ts

# All files in detail
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --all

# JSON output
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --file src/app.ts --json

# Custom context and truncation
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py \
  --file src/app.ts --context 5 --max-lines 80
```

**Requirements:** Python 3.9+ and Git. No external dependencies — uses only the standard library.

## Conflict types handled

- **Text conflicts** — Standard `<<<<<<<` / `=======` / `>>>>>>>` marker-based conflicts
- **Add/add** — Both sides added the same file
- **Deleted by ours/theirs** — One side deleted a file the other modified
- **Index-only** — Conflicts that don't produce worktree markers (e.g. mode changes)

## License

MIT
