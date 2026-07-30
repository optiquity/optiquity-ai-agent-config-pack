# Fenced-inert fixture

Every marker token below lives inside a backtick fence, so the pinned fence
predicate treats them all as INERT. Expected real (out-of-fence) tokens: 0.

## How to add project-owned content (illustrative only)

```
<!-- BEGIN project-owned -->
project additions go here
<!-- END project-owned -->
```

Even a second fenced example stays inert:

```markdown
<!-- BEGIN project-owned -->
<!-- END project-owned -->
```
