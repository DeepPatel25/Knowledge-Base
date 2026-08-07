# macOS Storage Inspection and Cleanup Commands

These commands cover common storage checks and cleanup options on macOS. Run one section at a time in Terminal, and review inspection output before deleting anything.

> [!WARNING]
> Do not use `sudo` for cleanup commands. Never delete `/System`, `/usr`, `/private`, `~/Library`, or `~/Library/Application Support` wholesale. The root-folder inspection command below is the only command in this guide that uses `sudo`; it does not delete anything.

## Check overall disk usage

Check available space on the startup disk:

```bash
df -h /
```

Inspect the main root-level folders:

```bash
sudo du -x -d 1 -h / 2>/dev/null | sort -hr
```

This command is inspection-only. macOS may still hide some protected data.

Check the folders in your home directory:

```bash
du -x -d 1 -h "$HOME" 2>/dev/null | sort -hr
```

## Check Downloads

List the 30 largest visible items in Downloads:

```bash
du -sh "$HOME"/Downloads/* 2>/dev/null | sort -h | tail -30
```

Open Downloads in Finder and remove only files you recognize:

```bash
open "$HOME/Downloads"
```

## Clean the npm cache

```bash
npm cache clean --force
npm cache verify
du -sh "$HOME/.npm"
```

This removes downloaded npm cache data, not project source files or installed project dependencies.

## Clean NuGet and .NET caches

```bash
dotnet nuget locals all --clear
du -sh "$HOME/.nuget"
```

Packages will be downloaded again when required.

## Inspect and clear general developer caches

Inspect the contents first:

```bash
du -sh "$HOME"/.cache/* 2>/dev/null | sort -h
```

Quit relevant development applications, review the inspection output, and then clear the contents if appropriate:

```bash
rm -rf "$HOME"/.cache/*
```

This preserves the `.cache` directory itself. Applications may recreate their cache files.

## Clean Homebrew

Run the standard cleanup commands:

```bash
brew cleanup
brew autoremove
du -sh "$(brew --cache)"
```

For more aggressive removal of old downloads:

```bash
brew cleanup --prune=all
```

## Inspect and clean Docker

Inspect Docker's disk usage:

```bash
docker system df
```

Remove unused containers, networks, dangling images, and build cache:

```bash
docker system prune
```

To also remove all images not used by a container:

```bash
docker system prune -a
```

Review Docker's confirmation carefully. Do not add `--volumes` unless you are certain unused volumes contain no database or project data.

## Review VS Code extensions

List installed extensions:

```bash
code --list-extensions
```

Remove a specific unused extension:

```bash
code --uninstall-extension publisher.extension-name
```

Replace `publisher.extension-name` with an exact identifier from the list. Do not delete the complete `~/.vscode` directory if you want to retain extensions.

## Inspect application caches

Show the 30 largest user application caches:

```bash
du -sh "$HOME"/Library/Caches/* 2>/dev/null | sort -h | tail -30
```

Quit the relevant application before removing one specific cache:

```bash
rm -rf "$HOME/Library/Caches/application.bundle.identifier"
```

Replace `application.bundle.identifier` with the exact folder name shown by the inspection command. Do not clear the entire `~/Library` directory.

## Inspect macOS per-user temporary storage

The exact path under `/var/folders` is user- and Mac-specific. Find the current user's temporary directory first:

```bash
getconf DARWIN_USER_TEMP_DIR
```

Store its parent directory for the following inspection commands:

```bash
USER_VAR_FOLDER="$(dirname "$(getconf DARWIN_USER_TEMP_DIR)")"
```

Check the complete per-user macOS cache and temporary tree:

```bash
du -sh "$USER_VAR_FOLDER"
```

Check its main areas:

```bash
du -sh "$USER_VAR_FOLDER"/{0,C,T,X} 2>/dev/null
```

List the largest temporary items:

```bash
find "$USER_VAR_FOLDER/T" -mindepth 1 -maxdepth 1 -print0 \
  | xargs -0 du -sh 2>/dev/null \
  | sort -hr \
  | head -30
```

Do not delete the complete `/var/folders` tree. macOS and running applications actively use it.

## Check results after cleanup

```bash
du -sh "$HOME/.npm" "$HOME/.cache" "$HOME/.nuget" \
  "$HOME/Downloads" 2>/dev/null
df -h /
```

Restart the Mac afterward if the Storage panel has not recalculated immediately.
