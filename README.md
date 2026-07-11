# wsl-dev-bootstrap

Repeatable bootstrap for Ubuntu WSL2 development instances.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Eclipse Temurin Java 11/17/21/25, Node.js 24, pnpm 10, Codex CLI, Maven, and a small set of common command-line development tools. Java 25, Node.js 24, pnpm 10, Maven, and Codex CLI are configured as global tools. The other Java versions remain installed and easy to select.
The base image setup also installs `wslu` so `gh auth login --web` can open a Windows browser from WSL when needed.

## Model

Use one clean Ubuntu installation as a base image, then import one WSL distribution per project.

Example:

```text
Ubuntu-24.04        clean base image
myproject           project-specific copy
anotherproject      another project-specific copy
```

Running `wsl --distribution Ubuntu-24.04` repeatedly launches the same registered distribution. It does not create new copies. A separate project instance is created with `wsl --import`, which gives it its own name and filesystem.

## Prerequisites

- Windows 10 or Windows 11 with WSL2
- Ubuntu 24.04 preferred, Ubuntu 22.04 where practical
- Internet access
- A normal Ubuntu user with sudo access
- Optional GitHub account for `gh auth login`

## Inspect WSL

PowerShell:

```powershell
wsl --list --online
wsl --list --verbose
wsl --list --running
```

`wsl --list --online` shows installable distributions. `wsl --list --verbose` shows registered local instances, their running/stopped state, and WSL version.

## One-Time Base Image Setup

1. Install Ubuntu 24.04 and complete the first-run user setup.
2. Inside that Ubuntu base distro, clone this repository and run `./base-install.sh`.
3. Export the distro when you are satisfied with the base image.

Install Ubuntu from PowerShell:

```powershell
wsl --install --distribution Ubuntu-24.04
```

Launch it and complete Ubuntu's first-run user setup:

```powershell
wsl --distribution Ubuntu-24.04
```

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/danielflower/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./base-install.sh
```

`./base-install.sh` also writes `/etc/wsl.conf` through `./scripts/configure-wsl.sh`, so the base image inherits your Windows-mount and interop settings before export.

Exit Ubuntu:

```bash
exit
```

Stop and export the clean base:

```powershell
wsl --terminate Ubuntu-24.04

wsl --export Ubuntu-24.04 `
    "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar"
```

Keep this tarball as the starting point for new project instances. Prefer exporting before GitHub authentication or other project-specific credentials, because credentials present at export time are copied into every imported instance.

## Create A Project Instance

Import the base tarball under the project name. This example creates a WSL distribution named `myproject`:

```powershell
New-Item -ItemType Directory -Force C:\WSL\myproject

wsl --import myproject `
    C:\WSL\myproject `
    "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar" `
    --version 2
```

Launch it:

```powershell
wsl --distribution myproject
```

The name `myproject` appears in `wsl --list --verbose` and is used with `wsl --distribution`, `wsl --terminate`, and `wsl --unregister`.

If the imported instance starts as root, either launch with a user explicitly:

```powershell
wsl --distribution myproject --user your-linux-username
```

Or set the default user inside the instance:

```bash
printf "[user]\ndefault=%s\n" "your-linux-username" | sudo tee /etc/wsl.conf
```

Then from PowerShell:

```powershell
wsl --terminate myproject
wsl --distribution myproject
```

## Bootstrap A Project Instance

If you used `./base-install.sh` in the base image, the repository checkout is already present in the inherited filesystem. Inside the project WSL instance:

```bash
cd wsl-dev-bootstrap
git pull --ff-only
./bootstrap.sh
```

The bootstrap is safe to rerun. It does not replace `.bashrc`; it updates one marked block:

```bash
# >>> wsl-dev-bootstrap >>>
# <<< wsl-dev-bootstrap <<<
```

For later updates in the same project instance, stay in that checkout and run:

```bash
git pull --ff-only
./bootstrap.sh
```

If you want a one-command local launcher, create that in your own home directory in the project instance. Keep the repository checkout itself as the source of truth.

Playwright is usually best installed in the project that uses it. When you need the browser binaries and Linux system dependencies, run:

```bash
npx playwright install --with-deps
```

That matches the official Playwright Linux guidance and avoids baking browser binaries into every base image.

## Optional Isolation From Windows

Use `/etc/wsl.conf` from `./scripts/configure-wsl.sh` if you want imported project instances to inherit Windows mount and interop isolation from the base image.

Then restart the project instance from PowerShell:

```powershell
wsl --terminate myproject
wsl --distribution myproject
```

After restart, `/mnt/c` should not be mounted automatically, Windows paths should not be appended to `PATH`, and Linux processes should not be able to launch Windows executables through WSL interop.

With automount disabled, prefer launching editors from Windows into WSL:

```powershell
code --remote wsl+myproject /home/your-linux-username/project
```

JetBrains IDEs can also connect to WSL through Remote Development from the Windows IDE UI. Keep project files in the WSL filesystem, for example under `/home/your-linux-username`.

Headed Linux GUI tools can still work through WSLg on supported Windows versions. For example, Playwright can launch Linux browsers installed in WSL and show their windows on the Windows desktop. That is different from launching Windows Chrome or Edge from Linux, which requires Windows interop.

This is useful isolation hygiene for project-specific instances, but it is not a hard security sandbox. Treat code running inside WSL as code running under your Windows user account, especially if you later mount Windows paths manually.

A bad agent running as root inside the distro can edit `/etc/wsl.conf` and re-enable automount or interop for that distro. That does not give it extra Windows rights beyond your Windows user account, but it does remove the WSL-side isolation you configured.

## Authenticate With GitHub

Authentication is per WSL instance. Authenticate each project instance independently:

```bash
./scripts/authenticate-github.sh
```

This uses GitHub CLI's browser or device-code flow:

```bash
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
```

No GitHub token is stored in this repository. Inspect or remove auth with:

```bash
gh auth status
gh auth logout --hostname github.com
```

If you want browser-based login to open a Windows browser from WSL, install `wslu` in the base image. That provides `wslview`, which `gh` can use when it cannot open a Linux desktop browser.

`gh auth login --web` uses GitHub's OAuth flow and requests the standard account-level scopes needed by Git operations. It does not let you limit access to an arbitrary list of repositories at login time. If you need repo-selected write access, create a fine-grained personal access token with selected repositories in GitHub settings, then feed that token to `gh` with `--with-token` or `GH_TOKEN` in the environment for automation.

## Verify

```bash
./verify.sh
```

Useful manual checks:

```bash
java -version
node --version
pnpm --version
npx --version
npm --version
mvn --version
codex --version
gh auth status
mise ls
```

Missing GitHub authentication is reported as a warning, not a bootstrap failure.

## Switching Java Versions

Current shell:

```bash
mise shell java@temurin-17
```

Helper:

```bash
./scripts/use-java 17
source ./scripts/use-java 17
```

Project-local version, run inside a project repository:

```bash
mise use java@temurin-21
```

Global default:

```bash
mise use --global java@temurin-25
```

Project-local mise configuration should normally be committed to the project repository, not this bootstrap repository.

## Update Tools

Update apt packages:

```bash
sudo apt-get update
sudo apt-get upgrade
```

Update mise from apt:

```bash
sudo apt-get update
sudo apt-get install --only-upgrade mise
```

Update patched releases within the configured major versions:

```bash
mise upgrade java@temurin-11 java@temurin-17 java@temurin-21 java@temurin-25
mise upgrade node@24
mise upgrade pnpm@10
mise upgrade maven@latest
mise upgrade npm:@openai/codex
```

Rerun bootstrap:

```bash
./bootstrap.sh
```

The bootstrap does not automatically move Java or Node.js to a different major version.

## Stop Or Remove Instances

Stop one instance:

```powershell
wsl --terminate myproject
```

Stop all WSL instances:

```powershell
wsl --shutdown
```

Permanently delete an instance:

```powershell
wsl --unregister myproject
```

`wsl --unregister` deletes that distribution's filesystem. Export a backup first if needed.

## Troubleshooting

`mise: command not found`: restart the shell or run `source ~/.bashrc`.

`JAVA_HOME` did not change: make sure mise activation is loaded, then open a new shell or run `cd .`.

Browser did not open during `gh auth login`: follow the device-code instructions printed by GitHub CLI.

GitHub CLI fell back to plaintext credential storage: configure a supported credential store, then rerun `gh auth login`.

Git clone asks for credentials: public repositories do not require authentication. Private repositories require `gh auth login` or another Git credential setup.

Corporate proxy or TLS interception: install the organization's trusted CA certificate correctly in Ubuntu. Do not disable certificate verification.

Imported WSL instance starts as root: launch with `--user` or set `/etc/wsl.conf` as shown above.

Accidental duplicate shell configuration: keep only the block between `# >>> wsl-dev-bootstrap >>>` and `# <<< wsl-dev-bootstrap <<<`.

## Security Model

This repository contains no secrets. GitHub authentication is performed locally in each WSL instance. Exporting an authenticated distribution copies its credentials, so prefer exporting a clean unauthenticated base image.

The bootstrap does not copy credentials from Windows, does not ask for personal access tokens, does not disable TLS verification, and does not execute unverified remote scripts.

## Customize

- Apt packages: `scripts/install-apt-packages.sh`
- Git defaults: `config/gitconfig` and `config/gitignore_global`
- Default Java version: `scripts/install-tools.sh` and `config/mise/config.toml`
- Node major version: `scripts/install-tools.sh` and `config/mise/config.toml`
- Additional mise tools: `scripts/install-tools.sh`

## License

MIT
