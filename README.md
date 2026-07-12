# wsl-dev-bootstrap

Repeatable bootstrap for Ubuntu WSL2 development instances.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Eclipse Temurin Java 11/17/21/25, Node.js 24, pnpm 10, Codex CLI, Maven, and common command-line development tools. Java 25, Node.js 24, pnpm 10, and Maven are configured as global mise tools. Codex CLI is installed through npm.

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

Open the distro either by selecting **Ubuntu 24.04 LTS** from the Windows Start
menu or by running this in PowerShell:

```powershell
wsl --distribution Ubuntu-24.04
```

At the Ubuntu shell prompt, clone and run the base installer:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/danielflower/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./base-install.sh
```

`./base-install.sh` writes `/etc/wsl.conf` for systemd, Windows mount isolation, and interop isolation.
It also installs `bubblewrap` and writes `~/.codex/config.toml` with full-access defaults for Codex CLI.

When you are satisfied with the base image, exit Ubuntu and export it:

```powershell
wsl --terminate Ubuntu-24.04
New-Item -ItemType Directory -Force F:\WSL

wsl --export Ubuntu-24.04 "F:\WSL\ubuntu-24.04-base.tar"
```

### Reset to a clean Ubuntu base

To discard all customizations and rebuild the base from the original Ubuntu
image, first exit Ubuntu. Then run the following in PowerShell. **This permanently
deletes everything in the `Ubuntu-24.04` distro and the previously exported base
tarball.** Project instances imported under other names are not affected.

```powershell
wsl --terminate Ubuntu-24.04
wsl --unregister Ubuntu-24.04
Remove-Item "F:\WSL\ubuntu-24.04-base.tar" -ErrorAction SilentlyContinue
wsl --install --distribution Ubuntu-24.04
```

Open the newly installed distro, create its Linux user when prompted, and repeat
the base installation and export steps above. If your base tarball is stored at a
different path, replace `F:\WSL\ubuntu-24.04-base.tar` accordingly.

## Project Instance

In PowerShell, set the project name once. Keep using the same PowerShell window
for the remaining commands in this section:

```powershell
$Project = "myproject"
$ProjectDir = "F:\WSL\$Project"
```

Create its directory and import the base tarball:

```powershell
New-Item -ItemType Directory -Force $ProjectDir

wsl --import $Project `
  $ProjectDir `
  "F:\WSL\ubuntu-24.04-base.tar" `
  --version 2
```

The first time you start the project instance, run its update immediately. This
pulls the latest repository changes and runs the complete bootstrap:

```powershell
wsl --distribution $Project --exec bash -lc '~/update.sh'
```

After the update completes, open an interactive shell:

```powershell
wsl --distribution $Project
```

Each interactive shell prints the commands for updating and verifying the
instance. `--exec` runs a command directly in the selected distro; `bash -lc`
supplies a login shell so that `~` resolves to the configured default user's home
directory.

## Bootstrap

Inside the project instance:

```bash
~/update.sh
```

The base installer creates `~/update.sh` in every subsequently imported custom
instance. The update script changes to the repository checkout, fast-forward
pulls the latest version, and runs `./bootstrap.sh`. Run it any time you want to
update apt packages and mise-managed tools in that instance.

## GitHub Auth

Authenticate this WSL instance independently:

```bash
~/wsl-dev-bootstrap/scripts/authenticate-github.sh
```

The script prints a prefilled fine-grained PAT creation URL, then prompts for the token.

Inspect or remove auth:

```bash
gh auth status
gh auth logout --hostname github.com
```

The URL pre-fills the token name, description, expiry, and permission flags. Pick only the repositories you want this WSL instance to access.

- `Contents`: write
- `Pull requests`: write
- `Issues`: read
- `Actions`: read
- `Statuses`: read

## Verify

```bash
~/wsl-dev-bootstrap/verify.sh
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
wsl --terminate $Project
```

Remove it:

```powershell
wsl --unregister $Project
```

`wsl --shutdown` stops all WSL instances.

## Customize

- Apt packages: `scripts/install-apt-packages.sh`
- WSL config: `scripts/configure-wsl.sh`
- Codex defaults: `scripts/configure-codex.sh`
- Git defaults: `config/gitconfig` and `config/gitignore_global`
- Global tools: `scripts/install-tools.sh`
- Shell activation: `scripts/configure-shell.sh`
- Java switching: `scripts/use-java`

## License

MIT
