<?php

declare(strict_types=1);
namespace OCA\HcNavigation\AppInfo;

use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;

class Application extends App implements IBootstrap {
    public const APP_ID = 'hc_navigation';
    public const VERSION = '1.0.0';
    public function __construct() { parent::__construct(self::APP_ID); }
    public function register(IRegistrationContext $context): void {}
    public function boot(IBootContext $context): void {}
}
