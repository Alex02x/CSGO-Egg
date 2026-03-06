<a name="readme-top"></a>

<div align="center">
  <h1 align="center">Greyweb @ degrando</h1>
  <h3 align="center">CSGO Egg</h3>
  <p align="center">
    Pterodactyl Egg for Counter-Strike: Global Offensive servers with automated updates, MetaMod + SourceMod auto-updaters, VPK sync, console filter, and junk cleaner.
  </p>
  <p align="center">
    Built for <strong>greyweb.cloud</strong> hosting
  </p>
</div>

---

## Features

### Automation & Updates

- **Auto-Updaters** → MetaMod 1.x and SourceMod automatically update on server restart
- **SteamCMD** → Automatic CSGO server installation and updates (AppID 740)
- **Centralized Update Script** → Auto-restart on CSGO updates with version tracking

### Storage & Performance

- **VPK Sync** → Massive storage savings via centralized file sharing and VPK symlinking
- **Junk Cleaner** → Automatic cleanup of old backups, logs, and demo files

### Management & Configuration

- **Console Filter** → Block unwanted console messages with configurable patterns
- **JSON Configs** → FTP-editable configuration files in `/egg/configs/`
- **Colored Logging** → Enhanced console output with log rotation
- **Custom Parameters** → Safe user-configurable startup options
- **Tokenless Servers** → Run servers without GSLT token (`-insecure` mode)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Supported Modding Frameworks

The egg automatically handles framework dependencies, load order, and `gameinfo.txt` configuration.

- **[MetaMod:Source 1.x](https://www.metamodsource.net/)** → Core plugin framework (required for SourceMod)
- **[SourceMod](https://www.sourcemod.net/)** → Scripting platform for CSGO plugins

Each framework can be enabled/disabled independently via Pterodactyl panel. Auto-updates on server restart while enabled.

### Game Modes

| game_type | game_mode | Mode |
|-----------|-----------|------|
| 0 | 0 | Casual |
| 0 | 1 | Competitive |
| 1 | 0 | Arms Race |
| 1 | 1 | Demolition |
| 1 | 2 | Deathmatch |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Quick Start

### 1. Import the Egg

Import `pterodactyl/degrando-csgo-egg.json` into your Pterodactyl panel.

### 2. Configure Docker Hub Credentials

Since the Docker image is private, configure Docker Hub credentials in Pterodactyl Wings:

Edit `/etc/pterodactyl/config.yml` on each Wings node:
```yaml
docker:
  registries:
    docker.io:
      username: "your-dockerhub-username"
      password: "your-dockerhub-token"
```

Restart Wings: `systemctl restart wings`

### 3. Build the Docker Image

```bash
# Build locally
./build.sh latest

# Build and push to private Docker Hub
./build.sh latest -d
```

### 4. Create a Server

Create a new server in Pterodactyl using the "Greyweb @ degrando CSGO Egg".

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Configuration Files

All configuration files are in `/home/container/egg/configs/`:

| File | Description |
|------|-------------|
| `console-filter.json` | Console message filter patterns |
| `cleanup.json` | Junk cleanup intervals and paths |
| `logging.json` | Log level and file rotation settings |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Credits

- [K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg) — Original CS2 egg this fork is based on
- [1zc/CS2-Pterodactyl](https://github.com/1zc/CS2-Pterodactyl) — Base Docker image concept

## License

Distributed under the GPL-3.0 License. See `LICENSE.md` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
