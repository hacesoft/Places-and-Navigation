# Places and Navigation 1.0.0 for Nextcloud

> **Publisher input archive:** This ZIP uses the final app-rooted format. NAS deployment helpers (`install.sh`, `uninstall.sh`, `build-release.sh`, `scripts/`) are not included. Any instructions referencing those files apply to the separate full-source GitHub repository, not this archive. The final signed App Store `.tar.gz` is produced by Hacesoft Publisher.


[Česky](README_CZ.md) · [Installation](docs/en/INSTALLATION.md) · [Core and updates](docs/en/CORE_AND_UPDATES.md)

Store and share favorite places, organize nested place lists, browse maps and hand routes off to Mapy.com, Google Maps or a custom navigation application in **Nextcloud 35**.

## Requirements

- Nextcloud 35 and PHP 8.3 or newer
- [Shared App Core](https://github.com/hacesoft/core) (`hc_shared_app_core`) **0.18.8 or newer**, installed and enabled first

## Installation

This public repository contains the ready-to-use Nextcloud application at the **repository root**:

```sh
cd /var/www/html/custom_apps
git clone https://github.com/hacesoft/Places-and-Navigation.git hc_navigation
cd /var/www/html
sudo -u www-data php occ app:enable hc_navigation
```

For optional Synology NAS / Docker deployment, extract or clone the repository **outside** `custom_apps` and run `sudo sh install.sh` in its root. The installer validates requirements, stages the new code and backs up existing code before deploying. It does not delete saved places or lists. Back up your Nextcloud installation before updating.

## Features

- Nested lists, favorites, search and sharing with users or groups
- Device location, map gestures and geocoding
- Navigation handoff to Mapy.com, Google Maps or a configured URL
- Czech, English, German, Spanish, French, Italian, Dutch, Polish, Portuguese, Slovak and Ukrainian translations

## Building

Runtime JS and CSS are included, with no npm/Composer build needed on the server. `sh build-release.sh` verifies language catalogs and creates runtime and source archives. Generated `release/` files are not part of the Git repository.

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE) and the [full license](https://www.gnu.org/licenses/agpl-3.0.txt).

Release history: [CHANGELOG.md](CHANGELOG.md). Czech: [CHANGELOG.cs.md](CHANGELOG.cs.md).

## Full source archive and Hacesoft Publisher

This GitHub/NAS project contains install.sh, uninstall.sh, build-release.sh, scripts/, docs/ and the installable Nextcloud runtime in src/. For NAS installation, extract the entire project and run `sudo sh install.sh` from its root. Do not copy the project root or scripts/ directly into Nextcloud custom_apps; the installer deploys src/. Publisher independently validates this full-source input and builds its own app-ID-rooted, signed distribution archive.
