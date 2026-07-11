# wsl-dev-bootstrap

Repeatable bootstrap for Ubuntu WSL2 development instances.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Eclipse Temurin Java 11/17/21/25, Node.js 24, pnpm 10, Codex CLI, Maven, and common command-line development tools. Java 25, Node.js 24, pnpm 10, Maven, and Codex CLI are configured as global tools.

The base image setup also installs `wslu` so `gh auth login --web` can open a Windows browser from WSL when needed.

## Prerequisites

- Windows 10 or Windows 11 with WSL2
- Ubuntu 24.04 preferred, Ubuntu 22.04 where practical
- Internet access
- A user with sudo access
- Optional GitHub account

## Base Image

Install Ubuntu 24.04:

```powershell
wsl --install --distribution Ubuntu-24.04
```

Open the distro, then clone and run the base installer:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/danielflower/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./base-install.sh
```

`./base-install.sh` writes `/etc/wsl.conf` for systemd, Windows mount isolation, and interop isolation.

When you are satisfied with the base image, exit Ubuntu and export it:

```powershell
wsl --terminate Ubuntu-24.04
wsl --export Ubuntu-24.04 "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar"
```

## Project Instance

Import the base tarball under a project name:

```powershell
New-Item -ItemType Directory -Force C:\WSL\myproject

wsl --import myproject `
  C:\WSL\myproject `
  "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar" `
  --version 2
```

Open it:

```powershell
wsl --distribution myproject
```

## Bootstrap

Inside the project instance:

```bash
cd wsl-dev-bootstrap
git pull --ff-only
./bootstrap.sh
```

Rerun `./bootstrap.sh` any time you want to update apt packages and mise-managed tools in that instance.

## GitHub Auth

Authenticate this WSL instance independently:

```bash
./scripts/authenticate-github.sh
```

Inspect or remove auth:

```bash
gh auth status
gh auth logout --hostname github.com
```

If browser login cannot open a Linux browser, `wslu` provides `wslview` as a Windows-browser bridge.

`gh auth login --web` uses GitHub OAuth scopes for Git operations. It does not let you choose an arbitrary repo allowlist at login time. If you need selected repositories, use a fine-grained personal access token with selected repos and pass that token to `gh` with `--with-token` or `GH_TOKEN`.

## Verify

```bash
./verify.sh
```

Manual checks:

```bash
java -version
node --version
pnpm --version
npm --version
npx --version
mvn --version
codex --version
gh auth status
mise ls
```

## Java

Current shell:

```bash
mise shell java@temurin-17
```

Helper:

```bash
./scripts/use-java 17
source ./scripts/use-java 17
```

Project-local:

```bash
mise use java@temurin-21
```

Global default:

```bash
mise use --global java@temurin-25
```

Playwright, when needed in a project:

```bash
npx playwright install --with-deps
```
## Remove

Stop one instance:

```powershell
wsl --terminate myproject
```

Remove it:

```powershell
wsl --unregister myproject
```

`wsl --shutdown` stops all WSL instances.

## Customize

- Apt packages: `scripts/install-apt-packages.sh`
- WSL config: `scripts/configure-wsl.sh`
- Git defaults: `config/gitconfig` and `config/gitignore_global`
- Global tools: `scripts/install-tools.sh`
- Shell activation: `scripts/configure-shell.sh`
- Java switching: `scripts/use-java`

## License

MIT
