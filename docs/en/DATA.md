[Česky](../cz/DATA.md) | **English**

# Data and sharing

Lists, nested lists, places, favorites, ordering and access permissions are stored by Shared App Core in the `hc_navigation` application namespace. Nextcloud applies its configured database prefix to Core tables. Navigation does not create its own application-specific database schema.

A list belongs to its owner. Sharing can target users or groups and grant read or edit access. A place may inherit list access or have an individual share. The owner can manage access. Read-only recipients cannot save edits.

Saved locations and list order remain available after reloading. Device location and map preferences are managed through Core and application settings. Address search uses Photon with OpenStreetMap data; route handoff opens the configured external map/navigation provider. That provider receives the supplied coordinates.
