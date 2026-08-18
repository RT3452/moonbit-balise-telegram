$ErrorActionPreference = "Stop"

moon version --all
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon info
moon run cmd/balise-inspect

if (Get-Command git -ErrorAction SilentlyContinue) {
  git diff --exit-code
}
