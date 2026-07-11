# wsl-dev-bootstrap

## Overview

This repository configures a repeatable Ubuntu WSL2 development environment with a secure, idempotent Bash bootstrap.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Maven, common command-line development utilities, Node.js 24, and Eclipse Temurin Java 11, 17, 21, and 25. Java 25 is the global default after bootstrap, while Java 11, 17, and 21 remain installed and easy to select. Node.js 24 and Maven are also globally active through mise.

## Prerequisites

- Windows 10 or Windows 11 with WSL2 support
- WSL2 enabled
- Ubuntu 24.04, or Ubuntu 22.04 where practical
- Internet access
- A non-root Ubuntu user with sudo access
- Optional: a GitHub account for `gh auth login`

## See Available Ubuntu Distributions

Run in PowerShell:

```powershell
wsl --list --online
```

Use the listed distribution name when installing a new instance.

## See Existing WSL Instances

Run in PowerShell:

```powershell
wsl --list --verbose
```

The output shows registered distributions, whether they are running or stopped, and whether each instance uses WSL version 1 or 2.

```powershell
wsl --list --running
```

This shows only distributions that are currently running.

## Create A New Ubuntu Instance

Check the exact distribution name first:

```powershell
wsl --list --online
```

Then install Ubuntu 24.04:

```powershell
wsl --install --distribution Ubuntu-24.04
```

Launch the named distribution:

```powershell
wsl --distribution Ubuntu-24.04
```

Store-installed distributions generally have fixed registered names. If you want several instances with custom names, use export/import or a downloaded root filesystem.

## Create A Per-Project Ubuntu Instance

WSL Store distributions have fixed registered names, so `wsl --install --distribution Ubuntu-24.04` cannot directly create a custom name such as `myproject`. For per-project instances, create or reuse a clean base Ubuntu distribution, export it, and import it under the project name.

First create and launch a clean base distribution:

```powershell
wsl --install --distribution Ubuntu-24.04
wsl --distribution Ubuntu-24.04
```

Inside Ubuntu, create your normal Linux user when prompted. Then configure imported copies to start as that user instead of root:

```bash
printf "[user]\ndefault=%s\n" "$USER" | sudo tee /etc/wsl.conf
```

Exit Ubuntu:

```bash
exit
```

Back in PowerShell, stop and export the base distribution:

```powershell
wsl --terminate Ubuntu-24.04

wsl --export Ubuntu-24.04 `
    "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar"
```

Import a project-specific instance named `myproject`:

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

The name `myproject` is what appears in `wsl --list --verbose`, and it is the name to use with `wsl --distribution`, `wsl --terminate`, and `wsl --unregister`.

## Clone An Existing WSL Instance

Stop the source distribution before export:

```powershell
wsl --terminate Ubuntu-24.04

wsl --export Ubuntu-24.04 `
    "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar"

New-Item -ItemType Directory -Force C:\WSL\Ubuntu-Dev

wsl --import Ubuntu-Dev `
    C:\WSL\Ubuntu-Dev `
    "$env:USERPROFILE\Downloads\ubuntu-24.04-base.tar" `
    --version 2
```

The imported instance has its own filesystem and registered name. Imported distributions may initially start as root, and the default user may need to be configured. Credentials present at export time are copied too, so prefer exporting an unauthenticated base image and authenticating GitHub separately in each imported instance.

Launch it:

```powershell
wsl --distribution Ubuntu-Dev
```

## Remove An Instance

This permanently deletes the distribution filesystem. Export a backup first if you need one.

```powershell
wsl --unregister Ubuntu-Dev
```

## Stop Instances

```powershell
wsl --terminate Ubuntu-Dev
wsl --shutdown
```

`wsl --terminate Ubuntu-Dev` stops one distribution. `wsl --shutdown` stops all WSL distributions and the WSL VM.

## Install This Bootstrap

Public repositories can be cloned without GitHub authentication.

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/OWNER/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./bootstrap.sh
```

Replace `OWNER` with the repository owner.

## Authenticate With GitHub

```bash
./scripts/authenticate-github.sh
```

This opens a browser or gives a one-time device code. No GitHub token is stored in this repository. GitHub CLI normally stores the credential in a secure credential store, but may fall back to a local plaintext file if no credential store is available in the WSL distribution.

Inspect authentication:

```bash
gh auth status
```

Log out:

```bash
gh auth logout --hostname github.com
```

## Verify The Installation

```bash
./verify.sh
```

Manual checks:

```bash
java -version
node --version
npm --version
mvn --version
gh auth status
mise ls
```

## Switching Java Versions

For the current shell:

```bash
mise shell java@temurin-17
```

The helper prints the command when executed:

```bash
./scripts/use-java 17
```

Or source it to update the current shell where mise activation is available:

```bash
source ./scripts/use-java 17
```

Use Java 11, 17, 21, or 25:

```bash
mise shell java@temurin-11
mise shell java@temurin-17
mise shell java@temurin-21
mise shell java@temurin-25
```

For a project-local version, run this inside the project repository:

```bash
mise use java@temurin-21
```

Project-local mise configuration should normally be committed to that project, not to this bootstrap repository.

For the global default:

```bash
mise use --global java@temurin-25
```

Do not use aliases that silently modify global configuration.

## Updating Tools

Update apt packages:

```bash
sudo apt-get update
sudo apt-get upgrade
```

Update mise when installed from apt:

```bash
sudo apt-get update
sudo apt-get install --only-upgrade mise
```

Install newer patched releases within the configured major lines:

```bash
mise upgrade java@temurin-11 java@temurin-17 java@temurin-21 java@temurin-25
mise upgrade node@24
mise upgrade maven@latest
```

Rerun the bootstrap safely:

```bash
./bootstrap.sh
```

The bootstrap does not automatically move Java or Node.js to a different major version.

## Troubleshooting

`mise: command not found`: restart your shell or run `source ~/.bashrc`. The bootstrap adds one managed mise activation block to `.bashrc`.

`JAVA_HOME` is not changing: use a shell with `mise activate bash` loaded, then run `cd .` to trigger mise environment refresh. Restart IDEs that read `JAVA_HOME` at startup.

Browser did not open during `gh auth login`: follow the device-code instructions printed by GitHub CLI.

GitHub CLI fell back to plaintext credential storage: install or configure a credential store supported by GitHub CLI, then rerun `gh auth login`.

Imported WSL instance starts as root: configure the default user for the imported distribution before running this bootstrap.

Git clone still asks for credentials: public repositories do not require authentication. Private repositories require `gh auth login` or another Git credential setup.

Corporate proxy or TLS interception: install the organization's trusted CA certificate correctly in Ubuntu. Do not disable certificate verification.

ARM64 tool availability: this bootstrap supports ARM64 where upstream apt repositories and mise-managed tools publish compatible builds.

WSL distribution is stopped: launch it with `wsl --distribution <Name>` from PowerShell.

Accidental duplicate shell configuration: this bootstrap manages only the block between `# >>> wsl-dev-bootstrap >>>` and `# <<< wsl-dev-bootstrap <<<`.

## Security Model

This repository contains no secrets. GitHub authentication is performed locally with GitHub CLI. Every WSL instance should receive its own login, and exporting an authenticated distribution copies its credentials.

Public repositories can be cloned without authentication. Private repositories require authentication. Revoke unused WSL credentials through GitHub account settings or by running:

```bash
gh auth logout --hostname github.com
```

The bootstrap does not copy credentials from `/mnt/c`, does not ask for personal access tokens, does not weaken TLS verification, and does not execute unverified remote scripts.

## Repository Customization

- Apt packages: edit `scripts/install-apt-packages.sh`
- Git defaults: edit `config/gitconfig` and `config/gitignore_global`
- Default Java version: edit `scripts/install-tools.sh` and `config/mise/config.toml`
- Node major version: edit `scripts/install-tools.sh` and `config/mise/config.toml`
- Additional mise-managed tools: edit `scripts/install-tools.sh`

## License

MIT
