---
name: xcode-checker
description: Checks for compilation errors in the iOS project using xcodebuild. Use this skill after editing Swift files to verify that the changes compile correctly and there are no build errors.
---

# Xcode Checker

This skill verifies the build integrity of the VEXHelper iOS project by running `xcodebuild` with `clean build analyze`.

It is configured to build for **iOS Simulator** to avoid signing issues during development.

## When to Use

- After editing any Swift file.
- Before committing changes.
- When you are unsure if your changes have introduced compilation errors.

## Usage

Run the bundled script to perform the check:

```bash
./.trae/skills/xcode-checker/scripts/check.sh
```

## Troubleshooting

If the build fails:
1.  **Read the error message**: Look for "error:" lines in the output.
2.  **Locate the file**: Note the file path and line number provided in the error.
3.  **Fix the code**: Edit the file to resolve the syntax error or type mismatch.
4.  **Re-run**: Run the script again to verify the fix.

## Configuration

The script currently targets `iPhone 17` simulator. If you need to change this, edit `.trae/skills/xcode-checker/scripts/check.sh`.
