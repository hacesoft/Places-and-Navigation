**Česky** | [English](README.md)

# Místa a navigace pro Nextcloud

Verze **1.0.0** · Nextcloud **35** · PHP **8.3 nebo novější**

Ukládání míst do seznamů, vnořené seznamy a oblíbená místa, sdílení seznamů i jednotlivých míst s uživateli a skupinami, vyhledávání adres a předání trasy Mapy.com, Google Maps nebo nastavené navigační aplikaci. Mapy podporují polohu zařízení a dotykové ovládání.

Součást rodiny aplikací Hacesoft. **[Hacesoft Shared App Core](https://github.com/hacesoft/core) 0.18.1 nebo novější je povinná závislost.** Nejprve nainstalujte a zapněte Core. Poskytuje společný layout, mapové poskytovatele, mezipaměť a služby polohy i ukládání seznamů, míst a sdílení.

## Instalace

Rozbalte tento úplný zdrojový archiv do samostatného adresáře na NASu. Obsahuje `install.sh`, `uninstall.sh`, hotovou aplikaci v `src/` a dokumentaci.

```sh
sudo sh ./install.sh
```

Instalátor aktualizuje aplikaci ve stávajícím Nextcloudu a vypíše původní/novou verzi a velikost instalace. Nerestartuje kontejnery. Pro odstranění prostudujte a spusťte `sudo sh ./uninstall.sh`.

[Návod k instalaci](docs/cz/INSTALLATION.md) · [Core a kontrola verzí](docs/cz/CORE_AND_UPDATES.md)

## Jazyky

čeština (`cs`), angličtina (`en`), němčina (`de`), španělština (`es`), francouzština (`fr`), italština (`it`), nizozemština (`nl`), polština (`pl`), portugalština (`pt`), slovenština (`sk`) a ukrajinština (`uk`). Rozhraní se řídí jazykem uživatele Nextcloudu. Pro nepodporovaný jazyk nebo chybějící překlad se použije angličtina. Dokumentace je pouze v češtině a angličtině.

## Repozitář a balíčky

[Zdrojový repozitář](https://github.com/hacesoft/Places-and-Navigation) · [Hlášení chyb](https://github.com/hacesoft/Places-and-Navigation/issues) · [Shared App Core](https://github.com/hacesoft/core)

Na GitHub zkopírujte **obsah** tohoto zdrojového adresáře přímo do kořene repozitáře, aby tam byly `README.md`, `README_CZ.md`, `src/`, instalační skripty a dokumentace. Verzi 1.0.0 určuje `src/appinfo/info.xml`. Adresář `release/` slouží pro vytvořené archivy. Příkaz `sh build-release.sh` zkontroluje jazyky a vytvoří aktuální runtime i úplný zdrojový archiv. Pro sestavení jsou potřeba Python 3, Node.js, zip a běžné shellové nástroje; při instalaci dodaného balíčku na server Nextcloudu tyto sestavovací nástroje nepotřebujete.

Licence **AGPL-3.0-or-later**; viz [LICENSE](LICENSE).

[Data a sdílení](docs/cz/DATA.md) · [Mobilní rozložení](docs/cz/MOBILNI_LAYOUT.md)
