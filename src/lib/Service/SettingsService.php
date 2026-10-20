<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Service;

use OCA\HcNavigation\AppInfo\Application;
use OCP\IConfig;
use OCP\IL10N;
use OCP\IUserSession;

class SettingsService {
    public const NAMESPACE = 'hc_navigation';
    public function __construct(private IConfig $config, private IUserSession $userSession, private IL10N $l) {}
    private function uid(): string { return $this->userSession->getUser()?->getUID() ?? ''; }
    private function nullableNumber(string $key): ?float {
        $value = $this->config->getUserValue($this->uid(), Application::APP_ID, $key, '');
        return $value !== '' && is_numeric($value) ? (float)$value : null;
    }
    public function load(): array {
        return [
            'mapLayer' => $this->config->getUserValue($this->uid(), Application::APP_ID, 'map_layer', 'osm'),
            'defaultZoom' => (int)$this->config->getUserValue($this->uid(), Application::APP_ID, 'default_zoom', '14'),
            'navigationProvider' => $this->config->getUserValue($this->uid(), Application::APP_ID, 'navigation_provider', 'ask'),
            'defaultTravelMode' => $this->config->getUserValue($this->uid(), Application::APP_ID, 'default_travel_mode', 'walking'),
            'directNavigation' => $this->config->getUserValue($this->uid(), Application::APP_ID, 'direct_navigation', '0') === '1',
            'customNavigationUrl' => $this->config->getUserValue($this->uid(), Application::APP_ID, 'custom_navigation_url', ''),
            'overlayOpacity' => (int)$this->config->getUserValue($this->uid(), Application::APP_ID, 'overlay_opacity', '88'),
            'lastLatitude' => $this->nullableNumber('last_latitude'),
            'lastLongitude' => $this->nullableNumber('last_longitude'),
            'lastAccuracy' => $this->nullableNumber('last_accuracy'),
            'lastLocatedAt' => $this->nullableNumber('last_located_at'),
        ];
    }
    public function validateAndSave(array $aValues): array {
        $sMapLayer = (string)($aValues['mapLayer'] ?? 'osm');
        $nDefaultZoom = (int)($aValues['defaultZoom'] ?? 14);
        $sProvider = (string)($aValues['navigationProvider'] ?? 'ask');
        $sMode = (string)($aValues['defaultTravelMode'] ?? 'walking');
        $bDirect = (bool)($aValues['directNavigation'] ?? false);
        $sCustomUrl = mb_substr(trim((string)($aValues['customNavigationUrl'] ?? '')), 0, 1000);
        $nOverlayOpacity = max(20, min(100, (int)($aValues['overlayOpacity'] ?? 88)));
        if (!in_array($sMapLayer, ['osm','cyclosm','topo','satelliteLabels','satellite'], true)) $sMapLayer = 'osm';
        if (!in_array($sProvider, ['ask','mapy','google','custom'], true)) $sProvider = 'ask';
        if (!in_array($sMode, ['walking','bicycling','driving'], true)) $sMode = 'walking';
        $nDefaultZoom = max(2, min(19, $nDefaultZoom));
        if ($sCustomUrl !== '' && !preg_match('#^https?://#i', $sCustomUrl)) throw new \InvalidArgumentException($this->l->t('Custom navigation URL must start with http:// or https://.'));
        $sUid = $this->uid();
        $this->config->setUserValue($sUid, Application::APP_ID, 'map_layer', $sMapLayer);
        $this->config->setUserValue($sUid, Application::APP_ID, 'default_zoom', (string)$nDefaultZoom);
        $this->config->setUserValue($sUid, Application::APP_ID, 'navigation_provider', $sProvider);
        $this->config->setUserValue($sUid, Application::APP_ID, 'default_travel_mode', $sMode);
        $this->config->setUserValue($sUid, Application::APP_ID, 'direct_navigation', $bDirect ? '1' : '0');
        $this->config->setUserValue($sUid, Application::APP_ID, 'custom_navigation_url', $sCustomUrl);
        $this->config->setUserValue($sUid, Application::APP_ID, 'overlay_opacity', (string)$nOverlayOpacity);
        if (array_key_exists('lastLatitude', $aValues) && array_key_exists('lastLongitude', $aValues)
            && is_numeric($aValues['lastLatitude']) && is_numeric($aValues['lastLongitude'])) {
            $nLatitude = (float)$aValues['lastLatitude'];
            $nLongitude = (float)$aValues['lastLongitude'];
            if ($nLatitude >= -90 && $nLatitude <= 90 && $nLongitude >= -180 && $nLongitude <= 180) {
                $this->config->setUserValue($sUid, Application::APP_ID, 'last_latitude', (string)$nLatitude);
                $this->config->setUserValue($sUid, Application::APP_ID, 'last_longitude', (string)$nLongitude);
                if (isset($aValues['lastAccuracy']) && is_numeric($aValues['lastAccuracy']) && (float)$aValues['lastAccuracy'] >= 0) {
                    $this->config->setUserValue($sUid, Application::APP_ID, 'last_accuracy', (string)(float)$aValues['lastAccuracy']);
                }
                if (isset($aValues['lastLocatedAt']) && is_numeric($aValues['lastLocatedAt']) && (float)$aValues['lastLocatedAt'] > 0) {
                    $this->config->setUserValue($sUid, Application::APP_ID, 'last_located_at', (string)(int)$aValues['lastLocatedAt']);
                }
            }
        }
        return $this->load();
    }
}
