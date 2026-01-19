# Commit Standard & Semantic Versioning

Universal CI automatically determines the next version number based on your commit history. By following a simple convention, you control semantic versioning (`MAJOR.MINOR.PATCH`) directly through your git workflow.

## 🚦 Quick Summary

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | **PATCH** `0.0.x` | `fix: Prevent crash on startup` |
| `feat:` | **MINOR** `0.x.0` | `feat: Add login via Google` |
| `BREAKING CHANGE:` | **MAJOR** `x.0.0` | `feat!: Remove v1 API endpoints`<br><br>`BREAKING CHANGE: API v1 is gone` |
| Other (`docs`, `chore`) | **PATCH** `0.0.x` | `docs: Update README` |

---

## 📝 Format Spec

We follow a subset of the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Structure
```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

---

## 🔍 How It Works

### Patch Release `v1.0.0` → `v1.0.1`
Triggers when you make backward-compatible bug fixes or internal changes (docs, style, chores).

**Examples:**
```bash
git commit -m "fix: Resolve index out of bounds error"
git commit -m "docs: Update installation guide"
git commit -m "chore: Update dependencies"
```

### Minor Release `v1.0.0` → `v1.1.0`
Triggers when you add **features** in a backward-compatible manner.

**Required:** The commit message must start with `feat`.

**Examples:**
```bash
git commit -m "feat: Add dark mode toggle"
git commit -m "feat(api): Add new /users/me endpoint"
```

### Major Release `v1.0.0` → `v2.0.0`
Triggers when you make incompatible API changes.

**Required:**
1. Text `BREAKING CHANGE:` or `breaking:` at the start of any line in the body or footer.
2. OR a `!` after the type (e.g., `feat!:`), though explicit footers are preferred for clarity.

**Examples:**
```bash
git commit -m "feat!: Switch to new configuration format

BREAKING CHANGE: The 'auth' field is now required in config.json"
```

```bash
git commit -m "refactor: Drop support for Node 14

breaking: Node 14 is end of life and no longer supported."
```

---

## 🤖 Automation Logic

The analyzer rules are strict but simple:

1. **Major**: If *any* commit contains `^BREAKING CHANGE:` or `^breaking:`.
2. **Minor**: If no major changes, but *at least one* commit starts with `^feat`.
3. **Patch**: If any other commits exist (fix, docs, chore, etc) and no major/minor triggers found.

### Interactive Safety
If a **Major** change is detected, the `pre-push` hook will interrupt and ask for confirmation to ensure you didn't accidentally introduce a breaking change.

```text
🔍 Breaking Changes Detected!
Has any breaking change been made to the API? [yes/no]:
```
