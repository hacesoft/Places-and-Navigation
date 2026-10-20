<?php

declare(strict_types=1);

namespace OCA\HcNavigation\Controller;

use OCA\HcNavigation\AppInfo\Application;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\Attribute\NoCSRFRequired;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\AppFramework\Http\ContentSecurityPolicy;
use OCP\IL10N;
use OCP\IRequest;
use OCP\IUserSession;

final class PageController extends Controller {
    public function __construct(
        IRequest $request,
        private IL10N $l10n,
        private IUserSession $session,
    ) {
        parent::__construct(Application::APP_ID, $request);
    }

    #[NoAdminRequired]
    #[NoCSRFRequired]
    public function index(): TemplateResponse {
        $sManifestPath = dirname(__DIR__, 2) . '/appinfo/hc_shared_app_core.json';
        $aManifest = [];
        if (is_file($sManifestPath) && is_readable($sManifestPath)) {
            $mDecoded = json_decode((string)file_get_contents($sManifestPath), true);
            if (is_array($mDecoded)) {
                $aManifest = $mDecoded;
            }
        }

        // install.sh validates the manifest strictly. The fallback keeps a
        // useful page diagnostic visible after an incomplete manual copy.
        $sRequiredCoreVersion = (string)($aManifest['requiredVersion'] ?? '0.18.1');
        $sCoreDownloadUrl = (string)($aManifest['downloadUrl'] ?? 'https://github.com/hacesoft/core/tree/HEAD/release');

        $response = new TemplateResponse(Application::APP_ID, 'main', [
            'appName' => $this->l10n->t('Places & Navigation'),
            'appVersion' => Application::VERSION,
            'uid' => $this->session->getUser()?->getUID() ?? '',
            'requiredCoreVersion' => $sRequiredCoreVersion,
            'requiredCoreApiVersion' => 1,
            'coreDownloadUrl' => $sCoreDownloadUrl,
        ]);
        $policy = new ContentSecurityPolicy();
        $policy->addAllowedImageDomain('blob:');
        $response->setContentSecurityPolicy($policy);
        return $response;
    }
}
