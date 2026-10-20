**Česky** | [English](../en/DATA.md)

# Data a sdílení

Seznamy, vnořené seznamy, místa, oblíbené položky, pořadí a oprávnění ukládá Shared App Core v prostoru aplikace `hc_navigation`. Na tabulky Core se používá nastavený prefix databáze Nextcloudu. Navigace nevytváří vlastní databázové schéma aplikace.

Seznam patří vlastníkovi. Sdílení může cílit na uživatele nebo skupiny a povolit čtení nebo úpravy. Místo může zdědit přístup ze seznamu nebo mít vlastní sdílení. Vlastník spravuje přístup. Příjemce s právem čtení nemůže ukládat změny.

Uložená místa a pořadí seznamů zůstávají dostupná po načtení stránky. Polohu zařízení a mapové předvolby spravuje Core a nastavení aplikace. Vyhledávání adres používá Photon s daty OpenStreetMap; předání trasy otevře nastaveného externího poskytovatele map nebo navigace, kterému se předají příslušné souřadnice.
