# Resolve Merge Conflicts — Warp Oz Skill

A [Warp](https://www.warp.dev) skill that teaches Oz (Warp's AI agent) how to resolve Git merge conflicts efficiently. Instead of reading entire conflicted files into context, the skill uses a compact extraction script that shows only the conflict hunks, surrounding context, and a unified diff between the two sides.

## Quick start

```bash
git clone https://github.com/warpdotdev-demos/resolve-merge-conflicts.git
cd resolve-merge-conflicts
./setup.sh
```

This creates two feature branches with realistic conflicts (config changes, utility rewrites, and an add/add file collision), then starts a merge that leaves the repo in a conflicted state.

Now open the repo in [Warp](https://www.warp.dev) and tell Oz:

> Resolve the merge conflicts in this repo

Oz will pick up the skill automatically and walk through the conflicts using the extraction script — summarizing, drilling into each file, resolving, and validating.

To reset and run it again:

```bash
./setup.sh --reset
./setup.sh
```

## What's included

```
.agents/skills/resolve-merge-conflicts/
├── SKILL.md                                # Skill definition (workflow + commands)
└── scripts/
    └── extract_conflict_context.py         # Python script for compact conflict extraction
setup.sh                                    # Demo setup (creates conflicts to resolve)
```

## Install in your own project

Copy the skill directory into any repo to give Oz the same capability there:

```bash
mkdir -p .agents/skills
cp -r path/to/resolve-merge-conflicts/.agents/skills/resolve-merge-conflicts .agents/skills/
```

Once the skill is in your project's `.agents/skills/` directory, Oz will automatically use it whenever it encounters merge conflicts.

## How Oz uses the skill

When Oz encounters merge conflicts (after a merge, rebase, cherry-pick, or stash pop), the skill guides it through:

1. **Summary** — Run the extraction script to get a compact overview of all conflicted files, their types, and hunk counts.
2. **Drill in** — Inspect one file at a time with only the conflict hunks, surrounding context, and a unified diff between ours and theirs.
3. **Resolve** — Take one side wholesale or edit the file directly to merge both changes.
4. **Validate** — Confirm no unmerged paths or leftover markers remain, then run project tests/linters.

## Standalone script usage

The Python script works independently of Warp:

```bash
# Summary of all conflicted files
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py

# Detailed view for one file
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --file src/config.ts

# All files in detail
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --all

# JSON output
python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py --file src/config.ts --json
```

**Requirements:** Python 3.9+ and Git. No external dependencies.

## Conflict types handled

- **Text conflicts** — Standard `<<<<<<<` / `=======` / `>>>>>>>` marker-based conflicts
- **Add/add** — Both sides added the same file
- **Deleted by ours/theirs** — One side deleted a file the other modified
- **Index-only** — Conflicts that don't produce worktree markers (e.g. mode changes)

## License

MIT
