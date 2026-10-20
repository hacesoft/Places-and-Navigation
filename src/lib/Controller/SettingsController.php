<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Controller;

use OCA\HcNavigation\AppInfo\Application;
use OCA\HcNavigation\Service\SettingsService;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\DataResponse;
use OCP\IRequest;

class SettingsController extends Controller {
    public function __construct(IRequest $request, private SettingsService $service) { parent::__construct(Application::APP_ID, $request); }
    #[NoAdminRequired]
    public function get(string $namespace = SettingsService::NAMESPACE): DataResponse {
        if ($namespace !== SettingsService::NAMESPACE) return new DataResponse(['error' => 'invalid_namespace'], 400);
        return new DataResponse(['values' => $this->service->load()]);
    }
    #[NoAdminRequired]
    public function save(string $namespace = SettingsService::NAMESPACE, array $values = []): DataResponse {
        if ($namespace !== SettingsService::NAMESPACE) return new DataResponse(['error' => 'invalid_namespace'], 400);
        try { return new DataResponse(['values' => $this->service->validateAndSave($values)]); }
        catch (\InvalidArgumentException $oError) { return new DataResponse(['error' => $oError->getMessage()], 400); }
    }
}
