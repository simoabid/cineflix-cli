# Production Deployment and Distribution Guide

To make `cineflix-cli` easily accessible to end-users without requiring manual steps like cloning the repository, downloading files, and resolving dependencies, we can use several modern packaging and distribution methods.

---

## 1. The Single-Command Shell Installer (Recommended)

The most popular way to distribute CLI scripts on UNIX-like environments (Linux, macOS, Termux) is a hosted installer script run via `curl` or `wget`.

### How it Works
The user runs:
```bash
curl -fsSL https://raw.githubusercontent.com/simoabid/cineflix-cli/master/install.sh | bash
```

### The Installer Script (`install.sh`)
This script automatically:
1. Detects the OS and distribution (Debian/Ubuntu, Fedora, Arch Linux, macOS, Termux, etc.).
2. Installs required system dependencies (`fzf`, `jq`, `curl`, `openssl`, `mpv`, `ffmpeg`, etc.) using the native package manager (`apt`, `dnf`, `pacman`, `brew`, `pkg`).
3. Downloads the latest version of the `cineflix-cli` script from the GitHub repository.
4. Installs the script to a directory in the user's `$PATH` (like `/usr/local/bin` or `$HOME/.local/bin`) and makes it executable.

> [!NOTE]
> We have created an production-ready, robust version of this installer script in the root of the repository as [install.sh](install.sh).

---

## 2. Advanced Packaging Alternatives

While a shell installer is great, some users prefer official package manager distribution. Here are the channels you can use:

### A. Homebrew Formula (macOS & Linux)
You can distribute the script via a custom Homebrew Tap.
1. Create a repository named `homebrew-tap` on GitHub.
2. Add a formula file `Formula/cineflix-cli.rb` with the following contents:
   ```ruby
   class CineflixCli < Formula
     desc "CLI to browse and watch anime, movies, and TV shows"
     homepage "https://github.com/simoabid/cineflix-cli"
     url "https://github.com/simoabid/cineflix-cli/archive/refs/tags/v1.0.0.tar.gz"
     sha256 "TARGET_TARBALL_SHA256_HERE"
     license "GPL-3.0"

     depends_on "fzf"
     depends_on "jq"
     depends_on "curl"
     depends_on "openssl"
     depends_on "ffmpeg"
     depends_on "aria2"
     depends_on "yt-dlp"

     def install
       bin.install "cineflix-cli"
     end

     test do
       system "#{bin}/cineflix-cli", "--version"
     end
   end
   ```
3. Users can then install it with:
   ```bash
   brew tap simoabid/tap
   brew install cineflix-cli
   ```

### B. Arch User Repository - AUR (Arch Linux)
The Arch package is already defined via the AUR. Maintain the `PKGBUILD` in the AUR to automate dependencies (`fzf`, `mpv`, `jq`, `openssl`, etc.).

### C. NPM Wrapper Package
Since the CLI depends on `node` for the optional local core, and many developers use npm, you can wrap `cineflix-cli` as a global npm package:
1. Set up a simple `package.json` in the root:
   ```json
   {
     "name": "cineflix-cli",
     "version": "1.0.0",
     "description": "CLI to watch movies, tv shows and anime",
     "bin": {
       "cineflix-cli": "./cineflix-cli"
     },
     "preferGlobal": true
   }
   ```
2. Publish to npm: `npm publish`.
3. Users can install it globally on any machine with:
   ```bash
   npm install -g cineflix-cli
   ```

---

## 3. Recommended Automated Release Workflow

To ensure seamless production updates, you can use GitHub Actions to automate version releases and push updates.

Create a GitHub workflow file `.github/workflows/release.yml`:
```yaml
name: Release Installer

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            cineflix-cli
            install.sh
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This ensures that whenever you tag a new version (e.g. `v1.0.1`), GitHub automatically compiles the release assets and updates the hosted installation files.
