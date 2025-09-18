Hermetic Developer Tools
========================

Purpose
- Provide stable, reproducible CLI tools within the repo without relying on the host/system.
- Install binaries into `tools/bin` and use them via `./tools/run <cmd>`.

What gets installed
- ripgrep (`rg`) – fast search across the repo.
- fd (`fd`) – fast file finder (replacement for `find`/`ls` for our use).
- jq (optional later) – JSON parsing; not required initially.
 - BusyBox (Linux only) – provides `sh`, `ls`, `grep`, `find`, etc. as a single binary for ultra-minimal sandboxes.

Quick start
1. macOS host tools:
   - `bash tools/bootstrap.sh` (auto-detects macOS and installs to `tools/bin/macos-<arch>`)
   - Use: `./tools/run rg --version`
2. Linux sandbox tools (for this CLI environment):
   - From your macOS host, run cross-target installs:
     - x86_64: `TARGET_OS=linux TARGET_ARCH=x86_64 bash tools/bootstrap.sh`
     - arm64: `TARGET_OS=linux TARGET_ARCH=arm64 bash tools/bootstrap.sh`
     - Installs go to `tools/bin/linux-<arch>`.
   - In the sandbox, use: `./tools/run-linux rg --version`
   - BusyBox usage in the sandbox (after installing above):
     - `./tools/run-linux busybox --help`
     - `./tools/run-linux busybox ls -la`
     - `./tools/run-linux busybox grep -R -n "pattern" .`

Permissions
- If you see `permission denied` running wrappers, set execute bits:
  - `chmod +x tools/run tools/run-linux tools/bootstrap.sh`

Why host-side?
- Some environments (like restricted sandboxes) lack download utilities (`curl`, `wget`, `python`) and archive tools (`tar`).
- Running the bootstrap on your machine ensures the binaries are fetched and unpacked reliably.

Manual install (if bootstrap can’t run)
- Create the directory: `mkdir -p tools/bin`
- Download appropriate archives for your OS/arch and copy the `rg` and `fd` binaries into `tools/bin`.

Pinned versions
- ripgrep: 14.1.1
- fd: 10.2.0

Download URLs
- macOS (arm64):
  - rg: https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-aarch64-apple-darwin.tar.gz
  - fd: https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-aarch64-apple-darwin.tar.gz
- macOS (x86_64):
  - rg: https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-apple-darwin.tar.gz
  - fd: https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-apple-darwin.tar.gz
- Linux (x86_64):
  - rg: https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz
  - fd: https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz
- Linux (arm64):
  - rg: https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-aarch64-unknown-linux-musl.tar.gz
  - fd: https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-aarch64-unknown-linux-musl.tar.gz

Checksums
- The bootstrap verifies checksums when `sha256sum`/`shasum` exist; otherwise it skips.
- If you require strict verification, compute your own SHA256 checksums for the archives and add them in the script where indicated.

Git hygiene
- `tools/bin/*` is ignored via `tools/.gitignore` so large binaries don’t get committed accidentally.
- You may commit them intentionally if desired; remove the ignore rule first.

Usage tips
- macOS host: use `./tools/run ...` (auto-selects `tools/bin/macos-<arch>`)
- Sandbox (Linux): use `./tools/run-linux ...` (searches `linux-x86_64` then `linux-arm64`)
- If a command isn’t found, re-run the bootstrap for the corresponding target.
