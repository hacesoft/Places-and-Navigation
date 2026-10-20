<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Controller;

use OCA\HcNavigation\AppInfo\Application;
use OCA\HcNavigation\Service\PickerService;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\Attribute\NoCSRFRequired;
use OCP\AppFramework\Http\DataResponse;
use OCP\IRequest;

class PickerController extends Controller {
    public function __construct(IRequest $request, private PickerService $service) { parent::__construct(Application::APP_ID, $request); }
    #[NoAdminRequired]
    #[NoCSRFRequired]
    public function search(string $query = '', string $types = 'user,group'): DataResponse {
        $aTypes = array_values(array_filter(array_map('trim', explode(',', $types))));
        return new DataResponse(['items' => $this->service->search($query, $aTypes)]);
    }
}
