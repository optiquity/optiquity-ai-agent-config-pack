# Apple app template

This template is for repositories that contain Apple client code only.

## Recommended commands

```bash
./scripts/bootstrap.sh
./scripts/test.sh
./scripts/validate.sh
```

## Notes

- `xcodebuild` validation remains intentionally generic until the repo has stable scheme and destination names.
- Add a repo-specific script once your app target and simulator destination are known.
