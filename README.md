# wsl-dev-bootstrap

Repeatable bootstrap for Ubuntu WSL2 development instances. The idea is that each "project" (one ore more related git repos in practice) have their own indepdent ubuntu images, managed through WSL2. There is no file mounting, and the coding agents can run in YOLO mode. Note that this is not fully hardened: root access is still achievable, and there is no outgoing network access restrictions or visibility. But it is safer than just running everything on a shared system, with file mounts to your host PC just sitting there. Also, GitHub auth is using fine grained tokens so you can restrict access to specific orgs or repos per project.

The bootstrap installs Git, GitHub CLI (`gh`), mise, Eclipse Temurin Java 11/17/21/25, Node.js 24, pnpm 10, Codex CLI, Maven, and common command-line development tools. Java 25, Node.js 24, pnpm 10, and Maven are configured as global mise tools. Codex CLI is installed through npm. 

## Base Image

Install Ubuntu 24.04 if you don't have it installed:

```powershell
wsl --install --distribution Ubuntu-24.04
```

If already installed, just open it:

```powershell
wsl --distribution Ubuntu-24.04
```

At the Ubuntu shell prompt, clone and run the base installer:

```bash
sudo apt-get update
sudo apt-get install -y git

cd ~
git clone https://github.com/danielflower/wsl-dev-bootstrap.git
cd wsl-dev-bootstrap
./base-install.sh
```

`./base-install.sh` writes `/etc/wsl.conf` for systemd, Windows mount isolation, and interop isolation.
It also installs `bubblewrap` and writes `~/.codex/config.toml` with full-access defaults for Codex CLI.

When you are satisfied with the base image, exit Ubuntu. In PowerShell, set the
WSL storage directory, create it, and export the base image. Keep using the same
PowerShell window for the project-instance commands:

```powershell
$WSLDir = "F:\WSL"
$BaseImage = Join-Path $WSLDir "ubuntu-24.04-base.tar"
New-Item -ItemType Directory -Force $WSLDir

wsl --terminate Ubuntu-24.04
wsl --export Ubuntu-24.04 $BaseImage
```

## Project Instance

In the same PowerShell window, set the project name, create its directory, and
import the base tarball:

```powershell
$Project = "myproject"
$ProjectDir = Join-Path $WSLDir $Project
New-Item -ItemType Directory -Force $ProjectDir

wsl --import $Project `
  $ProjectDir `
  $BaseImage `
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

Each interactive shell prints common setup and maintenance commands. `--exec`
runs a command directly in the selected distro; `bash -lc` supplies a login shell
so that `~` resolves to the configured default user's home directory.

## Bootstrap

Inside the project instance:

```bash
~/update.sh
```

The base installer creates `~/update.sh` in every subsequently imported custom
instance. The update script changes to the repository checkout, fast-forward
pulls the latest version, and runs `./bootstrap.sh`. Run it any time you want to
update apt packages and mise-managed tools in that instance.

### Reset to a clean Ubuntu base

To discard all customizations and rebuild the base from the original Ubuntu
image, first exit Ubuntu. Then run the following in PowerShell. **This permanently
deletes everything in the `Ubuntu-24.04` distro and the previously exported base
tarball.** Project instances imported under other names are not affected.

```powershell
wsl --terminate Ubuntu-24.04
wsl --unregister Ubuntu-24.04
Remove-Item "F:\WSL\ubuntu-24.04-base.tar" -ErrorAction SilentlyContinue
```

Then start again.

## Remove

Stop one instance:

```powershell
wsl --terminate $Project
```

Remove it:

```powershell
wsl --unregister $Project
```


## License

MIT
