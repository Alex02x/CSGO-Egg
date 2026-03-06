# Auto-Updaters

Automatically update MetaMod, SourceMod, SourceMod, and SourceMod on server startup with independent control per framework.

## Overview

The egg includes automatic updaters for popular CSGO server plugins with **multi-framework support** в†’ enable multiple frameworks simultaneously:

- **MetaMod:Source** в†’ Core plugin framework (required for SourceMod)
- **SourceMod (SourceMod)** в†’ C# plugin framework (.NET 8)
- **SourceMod** в†’ Standalone C# framework v2 (no MetaMod required)
- **SourceMod** в†’ Standalone C# platform with .NET 9 runtime

Updates happen automatically on server startup, keeping your plugins current without manual intervention.

**Version Tracking:** All addon versions are stored in `/home/container/egg/versions.txt`

## Configuration

### Multi-Framework Selection

Each framework has an independent boolean toggle in the Pterodactyl panel:

| Variable             | Description                                      | Auto-Updates |
| -------------------- | ------------------------------------------------ | ------------ |
| `INSTALL_METAMOD`    | MetaMod:Source (required for SourceMod)                | [вњ“]           |
| `INSTALL_SOURCEMOD`        | SourceMod (auto-enables MetaMod)        | [вњ“]           |
| `INSTALL_SWIFTLY`    | SourceMod standalone (no MetaMod required)       | [вњ“]           |
| `INSTALL_SourceMod`   | SourceMod standalone with .NET 9                  | [вњ“]           |

**Multi-Framework Examples:**
- MetaMod + SourceMod + SourceMod в†’ All three enabled simultaneously [вњ“]
- MetaMod + SourceMod в†’ Compatible combination [вњ“]
- SourceMod only в†’ MetaMod auto-enabled as dependency [вњ“]
- SourceMod + SourceMod в†’ SourceMod auto-disabled (incompatible) [вњ—]
- SourceMod + SourceMod в†’ SourceMod auto-disabled (incompatible) [вњ—]

### Setting Up

**Via Pterodactyl Panel:**

1. Go to **Startup** tab
2. Toggle checkboxes for desired frameworks:
   - в‘ MetaMod:Source
   - в‘ SourceMod
   - вђ SourceMod
   - в‘ SourceMod
3. Save and restart server

**Via Environment Variables:**

```bash
INSTALL_METAMOD=1
INSTALL_SOURCEMOD=1
INSTALL_SWIFTLY=0
INSTALL_SourceMod=1
```

### Dependency Handling

The egg automatically handles dependencies:

```
SourceMod enabled + MetaMod disabled
       в†“
[WARNING] SourceMod requires MetaMod:Source, auto-enabling...
       в†“
Both MetaMod and SourceMod installed
```

### Load Order Management

**MetaMod always loads first** after Game_LowViolence (critical for proper initialization):

```
Game_LowViolence    csgo_lv
            Game    csgo/addons/metamod        в†ђ Always first
            Game    csgo/addons/SourceMod
            Game    csgo/addons/SourceMod
            Game    sharp                       в†ђ SourceMod

            Game    csgo
```

## MetaMod:Source

### What It Does

- Downloads latest stable MetaMod from MetaMod downloads
- Extracts to `csgo/addons/metamod/`
- Configures `gameinfo.txt` automatically (always first position)
- Stores version in `/home/container/egg/versions.txt`

### How It Works

1. Checks current installed version
2. Fetches latest version from metamodsource.net
3. Compares versions (format: `2.x-devXXXX`)
4. Downloads and extracts if newer version available
5. Updates `gameinfo.txt` to load MetaMod first

### Console Output

```
[Degrando] > Checking MetaMod updates...
[Degrando] > Update available for MetaMod: 2.x-dev1245 (current: 2.x-dev1234)
[Degrando] > MetaMod updated to 2.x-dev1245
```

## SourceMod

### What It Does

- Downloads latest SourceMod from GitHub releases
- Extracts to `csgo/addons/SourceMod/`
- Installs with-runtime version (includes .NET runtime)
- Auto-enables MetaMod if not already enabled
- Stores version in `/home/container/egg/versions.txt`

### Prerequisites

- **MetaMod required** в†’ Automatically enabled when SourceMod is toggled on

### How It Works

1. Checks if MetaMod enabled (auto-enables with warning if not)
2. Checks current SourceMod version
3. Fetches latest release from roflmuffin/SourceMod
4. Downloads with-runtime Linux build
5. Extracts and updates version tracking

### Console Output

```
[Degrando] > [WARNING] SourceMod requires MetaMod:Source, auto-enabling...
[Degrando] > Checking SourceMod updates...
[Degrando] > SourceMod is up-to-date (v1.0.0)
```

### Plugin Compatibility

SourceMod updates may break plugins. Consider:

- Test updates on development server first
- Check plugin compatibility before updating
- Monitor SourceMod changelog for breaking changes
- Backup before enabling auto-updates

### Multi-Framework Compatibility

SourceMod can coexist with:
- [вњ“] MetaMod (required dependency)
- [вњ“] SourceMod
- [вњ—] SourceMod (incompatible - SourceMod auto-disabled if SourceMod enabled)

## SourceMod

### What It Does

- Downloads latest SourceMod from GitHub releases
- Extracts to `csgo/addons/SourceMod/`
- Installs with-runtime Linux version
- Configures `gameinfo.txt` automatically
- **Standalone** в†’ No MetaMod dependency
- Stores version in `/home/container/egg/versions.txt`

### Prerequisites

- **None** в†’ Completely standalone framework

### How It Works

1. Checks current SourceMod version
2. Fetches latest from swiftly-solution/SourceMod
3. Downloads with-runtimes-linux.zip
4. Extracts SourceMod directory
5. Updates `gameinfo.txt` to load SourceMod
6. Removes old metamod VDF file if present (legacy cleanup)

### Console Output

```
[Degrando] > Checking SourceMod updates...
[Degrando] > Update available for SourceMod: v0.2.38 (current: v0.2.37)
[Degrando] > SourceMod updated to v0.2.38
```

### Multi-Framework Compatibility

SourceMod can coexist with:
- [вњ“] SourceMod (SourceMod)
- [вњ“] MetaMod
- [вњ—] SourceMod (incompatible - auto-disabled if SourceMod enabled)

## SourceMod

### What It Does

- Downloads latest SourceMod from GitHub releases
- Installs .NET 9 runtime automatically
- Extracts to `game/sharp/`
- Configures `gameinfo.txt` automatically
- **Standalone** в†’ No MetaMod dependency
- Stores versions in `/home/container/egg/versions.txt`

### Prerequisites

- **None** в†’ Completely standalone with bundled .NET 9

### How It Works

1. Checks and installs .NET 9.0.0 runtime if needed
2. Checks current SourceMod version
3. Fetches latest from Kxnrl/SourceMod-public
4. Downloads core + extensions assets
5. Extracts preserving existing configs (`core.json` not overwritten)
6. Updates `gameinfo.txt` to load SourceMod

### Console Output

```
[Degrando] > Installing .NET 9.0.0 runtime...
[Degrando] > .NET 9.0.0 runtime installed successfully
[Degrando] > Checking SourceMod updates...
[Degrando] > Update available for SourceMod: git70 (current: git69)
[Degrando] > SourceMod updated to git70
```

### Configuration

SourceMod configs are in `game/sharp/configs/core.json`. First install creates default config, updates preserve your settings.

### Multi-Framework Compatibility

SourceMod can coexist with:
- [вњ“] MetaMod only
- [вњ—] SourceMod (SourceMod) - incompatible, auto-disabled if SourceMod enabled
- [вњ—] SourceMod - incompatible, auto-disabled if SourceMod enabled

**Note:** SourceMod is a standalone framework that conflicts with other C# frameworks. Only MetaMod can run alongside it.

## Version Tracking

### Version File

Versions are stored in `/home/container/egg/versions.txt`:

```
Metamod=2.x-dev1245
SourceMod=v1.1.0
Swiftly=v0.2.38
SourceMod=git70
DotNet=9.0.0
```

### Location

- **Path:** `/home/container/egg/versions.txt`
- **Accessible via FTP:** Yes
- **Backed up with server data:** Yes

### Smart Updates

The updater:

- [вњ“] Only downloads when new version available
- [вњ“] Compares versions before downloading
- [вњ“] Skips updates if already current
- [вњ“] Logs all version changes

This saves bandwidth and startup time.

## Update Schedule

### When Updates Happen

- **On server startup** в†’ Every time container starts
- **Not during runtime** в†’ Server must restart to update
- **After game updates** в†’ Auto-restart triggers update

### Forcing Updates

To force update:

1. Delete version file: `rm /home/container/egg/versions.txt` (via FTP or console)
2. Restart server
3. Will re-download latest versions

### Preventing Updates

To disable updates for specific framework:

1. Toggle off the framework checkbox in Pterodactyl panel
2. Or set environment variable to `0`: `INSTALL_SOURCEMOD=0`
3. Framework won't be updated or installed

## Combining with Auto-Restart

Auto-Restart + Auto-Updaters = Fully automated server:

```
CSGO Update Detected
       в†“
Server Restarts
       в†“
Game Files Update (SteamCMD)
       в†“
Plugins Update (Auto-Updaters)
       в†“
gameinfo.txt Load Order Verified
       в†“
Server Online with Latest Everything
```

Perfect for hands-off server management!

## Troubleshooting

### MetaMod Not Installing

**Check:**

- metamodsource.net accessible
- Sufficient disk space
- Write permissions on `csgo/addons/`

**Solution:**

```bash
# Check manually
curl -I https://www.metamodsource.net/downloads.php?branch=dev
```

### SourceMod Not Installing

**Check:**

- MetaMod auto-enabled (check for [WARNING] message)
- GitHub API not rate-limited
- Downloaded correct platform (Linux)
- Sufficient disk space

**Common error:**

```
[ERROR] No suitable asset found for roflmuffin/SourceMod
```

**Solution:** GitHub API rate limit в†’ wait 1 hour or check network access

### SourceMod Not Installing

**Check:**

- GitHub releases accessible
- Correct asset downloaded (with-runtimes-linux.zip)
- No file permission issues

**Note:** SourceMod is standalone, doesn't require MetaMod

### SourceMod Not Installing

**Check:**

- .NET runtime installation succeeded
- GitHub releases accessible
- Both core and extensions assets downloading
- Sufficient disk space for .NET 9 runtime

**Common issue:** .NET runtime download failure в†’ check Microsoft CDN access

### Version Not Updating

**Problem:** Same version reinstalls every startup

**Cause:** Version file not being written/read correctly

**Solution:**

1. Check `/home/container/egg/versions.txt` exists and is readable
2. Verify write permissions on `/home/container/egg/`
3. Check for errors in console during update
4. Delete version file and restart to regenerate

### Load Order Issues

**Problem:** Plugins not loading correctly

**Cause:** Incorrect gameinfo.txt load order

**Solution:** MetaMod must be first addon after LowViolence. The egg handles this automatically via `ensure_metamod_first()` function.

**Verify load order:**

```bash
cat csgo/gameinfo.txt | grep -A 10 "Game_LowViolence"
```

Should show:
```
Game_LowViolence    csgo_lv
            Game    csgo/addons/metamod        в†ђ MetaMod FIRST
            Game    csgo/addons/SourceMod
            ...other addons...

            Game    csgo
```

### Rate Limiting

**Error:** `API rate limit exceeded` or `403 Forbidden`

**Cause:** Too many requests to GitHub API

**Solution:**

- Wait 1 hour for rate limit reset
- Less frequent restarts during development
- Check GitHub status: https://www.githubstatus.com/

## Migration from Old System

### Deprecated ADDON_SELECTION Variable

If you're using the old `ADDON_SELECTION` dropdown:

**Warning Message:**
```
[Degrando] > [WARNING] DEPRECATION WARNING
[Degrando] > [WARNING] The ADDON_SELECTION variable is deprecated and will be removed in the next update!
[Degrando] > [WARNING] Please update your Pterodactyl egg to use the new multi-framework support:
[Degrando] > [WARNING]   в†’ INSTALL_METAMOD (boolean)
[Degrando] > [WARNING]   в†’ INSTALL_SOURCEMOD (boolean)
[Degrando] > [WARNING]   в†’ INSTALL_SWIFTLY (boolean)
[Degrando] > [WARNING]   в†’ INSTALL_SourceMod (boolean)
```

**Migration Steps:**

1. Download latest egg JSON from GitHub
2. Re-import egg in Pterodactyl panel
3. Configure new boolean variables to match your current setup:
   - Old: `ADDON_SELECTION="Metamod + SourceMod"`
   - New: `INSTALL_METAMOD=1` + `INSTALL_SOURCEMOD=1`
4. Restart server
5. Verify frameworks load correctly

**Backwards Compatibility:**

The old `ADDON_SELECTION` variable still works temporarily:

| Old Value                          | New Equivalent                      |
| ---------------------------------- | ----------------------------------- |
| `Metamod Only`                     | `INSTALL_METAMOD=1`                 |
| `Metamod + SourceMod`     | `INSTALL_METAMOD=1` + `INSTALL_SOURCEMOD=1` |
| `SourceMod`                        | `INSTALL_SWIFTLY=1`                 |
| `SourceMod`                         | `INSTALL_SourceMod=1`                |

This compatibility will be removed in the next major update!

## Best Practices

1. **Test updates** on dev server before production
2. **Backup plugins** before enabling auto-updates
3. **Monitor changelogs** for breaking changes
4. **Use multi-framework wisely** в†’ Test compatibility between frameworks
5. **Keep MetaMod updated** в†’ Required by SourceMod
6. **Check plugin compatibility** after updates
7. **Use stable releases** in production
8. **Enable only needed frameworks** в†’ Reduces startup time

## FAQ

**Q: Can I use SourceMod and SourceMod together?**
A: Yes! They are compatible frameworks and can coexist.

**Q: Can I use SourceMod and SourceMod together?**
A: No. SourceMod is incompatible with SourceMod. If SourceMod is enabled, SourceMod will be auto-disabled with a warning message.

**Q: Can I use SourceMod and SourceMod together?**
A: No. SourceMod is incompatible with SourceMod. If SourceMod is enabled, SourceMod will be auto-disabled with a warning message.

**Q: What frameworks are compatible with SourceMod?**
A: SourceMod is only compatible with MetaMod. It cannot run alongside SourceMod or SourceMod.

**Q: Will updates break my plugins?**
A: Possibly. Major updates can have breaking changes. Test on dev server first.

**Q: Can I rollback an update?**
A: Yes, manually install older version and toggle off auto-updates for that framework.

**Q: How do I update only MetaMod, not SourceMod?**
A: Toggle off SourceMod checkbox, keep MetaMod enabled.

**Q: Are beta versions supported?**
A: No, only stable releases from official repos.

**Q: What if GitHub is down?**
A: Updates will fail, but server will start anyway. Updates will work on next restart.

**Q: Can I auto-update custom plugins?**
A: Not built-in. You'll need to modify update scripts or manage them manually.

**Q: Where are versions stored?**
A: In `/home/container/egg/versions.txt` (accessible via FTP)

**Q: Does SourceMod require MetaMod?**
A: No! SourceMod v2 is standalone and doesn't require MetaMod.

**Q: Can I enable all 4 frameworks simultaneously?**
A: No. SourceMod is incompatible with SourceMod and SourceMod. Maximum 3 frameworks simultaneously: MetaMod + SourceMod + SourceMod. If you enable SourceMod with SourceMod/SourceMod, SourceMod will be auto-disabled with a warning.

## Related Documentation

- [VPK Sync & Centralized Updates](vpk-sync.md) в†’ Automatic CSGO updates and server restarts
- [Configuration Files](../configuration/configuration-files.md) в†’ All configuration options
- [Building from Source](../advanced/building.md) в†’ Customize update logic

## Support

Having update issues?

- [Report Issue](https://github.com/degrando/csgo-egg/issues)
- [Troubleshooting Guide](../advanced/troubleshooting.md)
