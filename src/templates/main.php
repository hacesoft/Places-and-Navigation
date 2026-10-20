<?php

declare(strict_types=1);

use OCP\Util;

// Nextcloud zajistí deterministické pořadí bez dynamického Guardu.
Util::addStyle('hc_shared_app_core', 'workspace');
Util::addStyle('hc_navigation', 'style-1.0.0');
Util::addScript('hc_shared_app_core', 'hc_shared_app_core');
Util::addScript('hc_navigation', 'core-lists-adapter');
Util::addScript('hc_navigation', 'app-1.0.0');
?>
<div
    id="hc-navigation-app"
    data-app-name="<?php p($_['appName']); ?>"
    data-app-version="<?php p($_['appVersion']); ?>"
    data-user-id="<?php p($_['uid']); ?>"
    data-required-core-version="<?php p($_['requiredCoreVersion']); ?>"
    data-required-core-api-version="<?php p($_['requiredCoreApiVersion']); ?>"
    data-core-download-url="<?php p($_['coreDownloadUrl']); ?>"
>
    <p class="hc-navigation-bootstrap-status" role="status"><?php p($l->t('Starting application…')); ?></p>
</div>
