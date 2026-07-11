# wsl-dev-bootstrap

Repeatable bootstrap for Ubuntu WSL2 development instances.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Eclipse Temurin Java 11/17/21/25, Node.js 24, Maven, and a small set of common command-line development tools. Java 25, Node.js 24, and Maven are configured as global mise defaults. The other Java versions remain installed and easy to select.

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

Install Ubuntu 24.04:

```powershell
wsl --install --distribution Ubuntu-24.04
```

Launch it and complete Ubuntu's first-run user setup:

```powershell
wsl --distribution Ubuntu-24.04
```

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

Inside the project WSL instance:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/danielflower/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./bootstrap.sh
```

The bootstrap is safe to rerun. It does not replace `.bashrc`; it updates one marked block:

```bash
# >>> wsl-dev-bootstrap >>>
# <<< wsl-dev-bootstrap <<<
```

## Optional Isolation From Windows

For project instances where you want fewer paths back to Windows, set this in the base image before export so every imported copy inherits it:

```bash
{
  printf '%s\n' \
    '[boot]' \
    'systemd=true' \
    '' \
    '[user]' \
    "default=$USER" \
    '' \
    '[automount]' \
    'enabled = false' \
    '' \
    '[interop]' \
    'enabled = false' \
    'appendWindowsPath = false'
} | sudo tee /etc/wsl.conf >/dev/null
```

If you already have `[boot]` and `[user]` in `/etc/wsl.conf`, keep them and add the new sections instead of replacing the file. The example above uses `$USER` from the current shell for the default user line.

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

## Verify

```bash
./verify.sh
```

Useful manual checks:

```bash
java -version
node --version
npm --version
mvn --version
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
mise upgrade maven@latest
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
