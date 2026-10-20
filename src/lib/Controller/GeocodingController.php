<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Controller;

use OCA\HcNavigation\AppInfo\Application;
use OCA\HcNavigation\Service\GeocodingService;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\DataResponse;
use OCP\IRequest;

class GeocodingController extends Controller {
    public function __construct(IRequest $request, private GeocodingService $service) { parent::__construct(Application::APP_ID, $request); }
    #[NoAdminRequired]
    public function search(string $q = '', string $lat = '', string $lon = ''): DataResponse {
        $aPayload = $this->service->search($q, $lat, $lon, $this->request->getHeader('Accept-Language'));
        $nStatus = (int)($aPayload['_status'] ?? 200); unset($aPayload['_status']);
        return new DataResponse($aPayload, $nStatus);
    }
}
