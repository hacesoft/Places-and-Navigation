# Místa a navigace 1.0.0 pro Nextcloud

> **Vstupní archiv pro Publisher:** Tento ZIP má výslednou strukturu s jediným kořenovým adresářem aplikace. Neobsahuje NAS nástroje (`install.sh`, `uninstall.sh`, `build-release.sh`, `scripts/`). Návody, které je zmiňují, platí pro samostatný úplný zdrojový repozitář, nikoli pro tento archiv. Podepsaný `.tar.gz` pro App Store vytváří až Hacesoft Publisher.


[English](README.md) · [Instalace](docs/cz/INSTALLATION.md) · [Core a aktualizace](docs/cz/CORE_AND_UPDATES.md)

Aplikace pro ukládání oblíbených míst, vnořené seznamy, sdílení, mapy a předání navigace do Mapy.com, Google Maps nebo vlastní navigační aplikace v **Nextcloudu 35**.

## Požadavky

- Nextcloud 35 a PHP 8.3 nebo novější
- [Shared App Core](https://github.com/hacesoft/core) (`hc_shared_app_core`) **0.18.8 nebo novější**, předem nainstalovaný a zapnutý

## Instalace

Veřejný repozitář obsahuje běhové soubory aplikace přímo **v kořeni**, lze ho tedy naklonovat do `custom_apps/hc_navigation`:

```sh
cd /var/www/html/custom_apps
git clone https://github.com/hacesoft/Places-and-Navigation.git hc_navigation
cd /var/www/html
sudo -u www-data php occ app:enable hc_navigation
```

Pro volitelné nasazení na Synology NAS / Dockeru rozbalte repozitář **mimo** `custom_apps` a v jeho kořeni spusťte `sudo sh install.sh`. Skript kontroluje požadavky, připraví soubory a zálohuje předchozí instalaci. Uložená místa a seznamy nemaže. Před aktualizací proveďte zálohu Nextcloudu.

## Funkce

- Vnořené seznamy míst, oblíbené položky, vyhledávání a sdílení
- Poloha zařízení, ovládání mapy a geokódování
- Navigace přes Mapy.com, Google Maps nebo vlastní URL
- Překlady CS, EN, DE, ES, FR, IT, NL, PL, PT, SK a UK

## Sestavení

Aplikace již obsahuje potřebné JS a CSS; server nepotřebuje npm ani Composer. `sh build-release.sh` kontroluje překlady a vytváří runtime a zdrojové archivy. Výstupy v `release/` do Gitu nepatří.

## Licence

AGPL-3.0-or-later. Viz [LICENSE](LICENSE) a [úplné znění licence](https://www.gnu.org/licenses/agpl-3.0.txt).

Veřejná historie vydání: [CHANGELOG.md](CHANGELOG.md). Český přehled: [CHANGELOG.cs.md](CHANGELOG.cs.md).

## Úplný zdrojový balíček a Hacesoft Publisher

Balíček pro GitHub a instalaci na NAS obsahuje `install.sh`, `uninstall.sh`, `build-release.sh`, adresáře `scripts/`, `docs/` a hotovou aplikaci v `src/`. Pro instalaci na NAS rozbalte celý projekt a v jeho kořeni spusťte `sudo sh install.sh`. Do `custom_apps` se kopíruje pouze běhový obsah `src/`, nikoliv dokumentace projektu a instalační skripty. Publisher následně provede vlastní kontrolu a sestaví distribuční archiv s kořenovým adresářem podle ID aplikace; zdejší zdrojový ZIP není přímo distribuční TAR.GZ.
