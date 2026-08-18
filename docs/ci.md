# CI and toolchain checks

The workflow follows the current \`moonbit-community/.github/workflow-templates/check.yml\` shape and the cross-platform setup used by the reference MoonBit repositories.

## Local command set

\`\`\`text
moon version --all
moon fmt --check
moon info
git diff --exit-code
moon check --deny-warn
moon test --deny-warn
moon run cmd/balise-inspect
\`\`\`

The current Moon CLI (0.1.20260807 / moonc 0.10.7) does not expose \`--deny-warn\` on \`moon fmt\` or \`moon info\`; those commands fail fast on their supported cleanliness checks instead. \`--deny-warn\` is applied to \`moon check\` and \`moon test\`, where the CLI supports it. This is the compatible equivalent of the requested strict pipeline for MoonBit 0.10.3+.

Run \`pwsh ./scripts/check.ps1\` on Windows. The CI job additionally checks Ubuntu, macOS and Windows. No network push or publishing action is included.
