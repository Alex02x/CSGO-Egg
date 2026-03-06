# Degrando CSGO Egg Documentation

Welcome to the documentation for the Degrando CSGO Pterodactyl Egg! This guide covers installation, configuration, and all features.

## Quick Start

New to this egg? Start here:

1. **[Installation Guide](getting-started/installation.md)** - Install the egg in Pterodactyl

2. **[Quick Start](getting-started/quickstart.md)** - Get your server running

3. **[Updating Guide](getting-started/updating.md)** - Keep everything up to date

## Table of Contents

### Getting Started

- [Installation](getting-started/installation.md) - How to install and apply the egg

- [Quick Start](getting-started/quickstart.md) - Get your server running quickly

- [Updating](getting-started/updating.md) - Update the egg, Docker image, and server

### Features

- [VPK Sync & Centralized Updates](features/vpk-sync.md) - 80% storage savings + automatic CSGO updates

- [Auto-Updaters](features/auto-updaters.md) - MetaMod and SourceMod support with independent toggles

### Configuration

- [Configuration Files](configuration/configuration-files.md) - JSON-based configuration system

### Advanced

- [Building from Source](advanced/building.md) - Build your own Docker image

- [GDB Debugging](advanced/debugging.md) - Remote debugging with GDB

- [Troubleshooting](advanced/troubleshooting.md) - Common issues and solutions

## Key Features

This egg includes many powerful features:

- **Auto-Restart** - Detect CSGO updates and restart automatically

- **Auto-Updaters** - Keep MetaMod and SourceMod updated

- **VPK Sync** - Save storage per server with centralized files

- **Junk Cleaner** - Automatic cleanup configured via JSON

- **Colored Logs** - Enhanced console output with rotation

- **Console Filter** - Pattern-based message filtering

- **Tokenless Servers** - Run servers without GSLT token via `-insecure`

- **Flexible** - Works with Pterodactyl or standalone Docker

## Common Tasks

### Install a New Server

1. Download the egg from `pterodactyl/degrando-csgo-egg.json`

2. Import into Pterodactyl

3. Create a new server with the egg

4. Start and enjoy!

[Full Installation Guide в†’](getting-started/installation.md)

### Enable Auto-Restart

1. Set up VPK Sync for centralized CSGO files

2. Configure the centralized update script

3. Add to cron for automatic checks

4. Servers restart automatically on CSGO updates!

[VPK Sync & Centralized Updates Guide в†’](features/vpk-sync.md)

### Build Custom Image

```bash
./build.sh my-tag
docker push degrando/csgo-egg:my-tag
```

[Building Guide в†’](advanced/building.md)

## Need Help?

If you need assistance:

1. Check the [Troubleshooting Guide](advanced/troubleshooting.md)

2. Review the [Configuration Files](configuration/configuration-files.md) documentation

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE.md](../LICENSE.md) file for details.

## Credits

- **[K4ryuu](https://github.com/K4ryuu)** - Original [CS2-Egg](https://github.com/K4ryuu/CS2-Egg) this project is based on

- **[1zc](https://github.com/1zc)** - Original [CS2-Pterodactyl](https://github.com/1zc/CS2-Pterodactyl) base image

- **[Poggu](https://github.com/Poggicek)** - Console filter inspiration from [CleanerCS2](https://github.com/Source2ZE/CleanerCS2)

Made with care by Greyweb @ degrando

---

<div align="center">
  <p>Made with в™Ґ by <a href="https://github.com/Greyweb">Greyweb</a> @ <a href="https://kitsune-lab.com">Degrando</a></p>
  <p>
    <a href="https://github.com/degrando/csgo-egg">в­ђ Star on GitHub</a>
  </p>
</div>
