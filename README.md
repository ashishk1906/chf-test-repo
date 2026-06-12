# CHF Test Repo

A deterministic repo-history generator for testing Consolidated Hot Fix (CHF)
agents and harness workflows.

This repository does not contain one fixed application history. Instead, it
contains a scenario-driven repo factory. Each generated repository has Airtel,
Reliance, and Tata tenant branches, seeded commits, release branches,
scenario-specific changes, and an `expected.json` file that describes the
expected outcome for evaluation.

## What This Tests

The generated repositories are useful for testing:

- release engineering workflows
- tenant-specific maintenance branches
- cherry-pick propagation decisions
- conflict detection
- rewritten-history detection
- generated-file handling
- missing dependency detection
- dirty worktree preflight checks
- CHF agent and harness evaluation flows

## Repository Generator

The main Python factory is:

```text
scripts/repo_factory.py
```

The shell entrypoint is:

```text
create_repo.sh
```

Scenario definitions live under:

```text
scenarios/*.yaml
```

The factory creates local git repositories under:

```text
output/<scenario>/repo
```

Each scenario also gets:

```text
output/<scenario>/expected.json
output/<scenario>/manifest.json
```

The script does not push to GitHub automatically. It builds the local repo
history first. After that, you can push any generated scenario repo to GitHub.

## Repository Model

Every generated scenario repo has this branch model:

```text
main
|-- release/1.0.0
|-- release/1.1.0
|-- tenant/airtel-v1.0.0
|-- tenant/reliance-v1.0.0
`-- tenant/tata-v1.0.0
```

A/R/T tenants mean:

```text
A = Airtel
R = Reliance
T = Tata
```

## Authors

The generated commits use fictional authors:

```text
Kavya Menon       - main/platform development
Dev Malhotra      - release engineering
Neha Rao          - Airtel tenant work
Arjun Sethi       - Reliance tenant work
Leela Krishnan    - Tata tenant work
```

## Scenarios

The script supports these scenarios:

```text
clean_cherry_pick
conflicting_cherry_pick
rewritten_history
generated_files
missing_dependency_commit
dirty_worktree
```

### clean_cherry_pick

A fix exists on `release/1.0.0` and should cherry-pick cleanly onto:

```text
tenant/airtel-v1.0.0
```

Expected result:

```text
clean
```

### conflicting_cherry_pick

A release-line fix changes `src/auth/session.py`, while Reliance has already
changed the same file differently.

Expected result:

```text
blocked
CHERRY_PICK_CONFLICT
```

### rewritten_history

The same effective patch already exists on Tata, but with a different commit
SHA.

Expected result:

```text
already_applied_equivalent_patch
```

This exercises agent logic such as `git patch-id` or `git range-diff`.

### generated_files

A fix changes both source/config data and a generated file:

```text
config/runtime.json
dist/generated_config.json
```

Expected result:

```text
clean_with_generated_exclusion
```

The generated file should be treated as rebuildable output, not blindly copied
into a package.

### missing_dependency_commit

The selected hotfix depends on an earlier commit that was not selected.

Expected result:

```text
blocked
MISSING_DEPENDENCY_COMMIT
```

### dirty_worktree

The target tenant branch has uncommitted changes before the hotfix is applied.

Expected result:

```text
blocked
DIRTY_WORKTREE
```

## How To Run

Use Git Bash on Windows.

Go to this folder:

```bash
cd /c/Users/aks89/Desktop/chf-test-repo
```

If you are using the copy inside `chf-testbed`, use:

```bash
cd /c/Users/aks89/Desktop/chf-testbed/chf-test-repo
```

List available scenarios:

```bash
python scripts/repo_factory.py --list
```

Generate all scenarios:

```bash
python scripts/repo_factory.py --scenario all --output ./output
```

Generate one scenario:

```bash
python scripts/repo_factory.py --scenario clean_cherry_pick --output ./output
```

Use a custom output folder:

```bash
python scripts/repo_factory.py --scenario all --output ./my-output
```

You can also use the shell wrapper:

```bash
./create_repo.sh --scenario all --output ./output
./create_repo.sh --scenario clean_cherry_pick --output ./output
```

## Output Layout

After running all scenarios, the output looks like:

```text
output/
  clean_cherry_pick/
    repo/
    expected.json
    manifest.json
  conflicting_cherry_pick/
    repo/
    expected.json
    manifest.json
  rewritten_history/
    repo/
    expected.json
    manifest.json
  generated_files/
    repo/
    expected.json
    manifest.json
  missing_dependency_commit/
    repo/
    expected.json
    manifest.json
  dirty_worktree/
    repo/
    expected.json
    manifest.json
```

## Viewing History

Open one generated repo:

```bash
cd output/clean_cherry_pick/repo
```

View branches:

```bash
git branch
```

Expected branches:

```text
main
release/1.0.0
release/1.1.0
tenant/airtel-v1.0.0
tenant/reliance-v1.0.0
tenant/tata-v1.0.0
```

View the graph:

```bash
git log --graph --decorate --oneline --all
```

View commit authors:

```bash
git log --format='%an <%ae>' --all | sort -u
```

View the scenario expectation:

```bash
cd ..
cat expected.json
```

Important fields in `expected.json`:

```text
scenario
branches.source
branches.target
source_shas
expected_result
blockers
generated_files
evidence_commands
```

## Example Agent Flow

For `clean_cherry_pick`, an agent or harness can read `expected.json` and replay
the intended check:

```bash
cd output/clean_cherry_pick/repo
git checkout tenant/airtel-v1.0.0
git status --short
git cherry-pick <source_sha_from_expected_json>
```

The expected result for this scenario is `clean`.

For `conflicting_cherry_pick`, the same style of replay should produce a
conflict and the expected blocker is `CHERRY_PICK_CONFLICT`.

## Push A Scenario Repo To GitHub

The factory creates local repos only. To show one generated repo on GitHub like
a normal repository page, create an empty GitHub repo first.

Example for `clean_cherry_pick`:

```bash
cd /c/Users/aks89/Desktop/chf-test-repo
python scripts/repo_factory.py --scenario clean_cherry_pick --output ./output
cd output/clean_cherry_pick/repo
```

Add the GitHub remote:

```bash
git remote add origin git@github.com:<user-or-org>/<repo-name>.git
```

Push all branches:

```bash
git push -u origin --all
```

Push tags:

```bash
git push origin --tags
```

For HTTPS instead of SSH:

```bash
git remote add origin https://github.com/<user-or-org>/<repo-name>.git
git push -u origin --all
git push origin --tags
```

If you generate all scenarios, each scenario is a separate git repo. Usually,
push each scenario repo to a separate GitHub repository.

## Folder Contents

Before running:

```text
chf-test-repo/
  create_repo.sh
  scripts/
    repo_factory.py
  scenarios/
    clean_cherry_pick.yaml
    conflicting_cherry_pick.yaml
    rewritten_history.yaml
    generated_files.yaml
    missing_dependency_commit.yaml
    dirty_worktree.yaml
  README.md
```

After running:

```text
chf-test-repo/
  create_repo.sh
  scripts/
  scenarios/
  README.md
  output/
```
