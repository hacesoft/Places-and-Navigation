# Places and Navigation 1.0.0 for Nextcloud


[Česky](README_CZ.md) · [Installation](docs/en/INSTALLATION.md) · [Core and updates](docs/en/CORE_AND_UPDATES.md)

Store and share favorite places, organize nested place lists, browse maps and hand routes off to Mapy.com, Google Maps or a custom navigation application in **Nextcloud 35**.

## Requirements

- Nextcloud 35 and PHP 8.3 or newer
- [Shared App Core](https://github.com/hacesoft/core) (`hc_shared_app_core`) **0.18.8 or newer**, installed and enabled first

## Installation

The ready-to-use Nextcloud application is in `src/`, not at the repository root. For a Synology NAS / Docker installation, clone the project **outside** `custom_apps` and run:

```sh
git clone https://github.com/hacesoft/Places-and-Navigation.git
cd Places-and-Navigation
sudo sh install.sh
```

The installer validates requirements, stages the new code and backs up existing code before deploying. On other environments, deploy **only the contents of `src/`** into `custom_apps/hc_navigation/`, set appropriate file permissions, and enable it with `occ app:enable hc_navigation` as the web-server user. It does not delete saved places or lists. Back up Nextcloud before updating.

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
