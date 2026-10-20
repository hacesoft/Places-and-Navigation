<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Service;

use OCA\HcNavigation\AppInfo\Application;
use OCP\Http\Client\IClientService;
use Psr\Log\LoggerInterface;

class GeocodingService {
    public function __construct(private IClientService $clientService, private LoggerInterface $logger) {}

    public function search(string $sQuery, string $sLatitude = '', string $sLongitude = '', string $sLanguage = ''): array {
        $sQuery = trim($sQuery);
        if (mb_strlen($sQuery) < 3) return ['results' => []];
        $aParams = ['q' => $sQuery, 'limit' => 6];
        if ($sLatitude !== '' && $sLongitude !== '' && is_numeric($sLatitude) && is_numeric($sLongitude)) {
            $nLatitude = (float)$sLatitude;
            $nLongitude = (float)$sLongitude;
            if (is_finite($nLatitude) && is_finite($nLongitude)) {
                $aParams['lat'] = max(-90.0, min(90.0, $nLatitude));
                $aParams['lon'] = max(-180.0, min(180.0, $nLongitude));
            }
        }
        if (preg_match('/^[A-Za-z]{2}/', $sLanguage, $aMatch)) {
            $sRequestedLanguage = strtolower($aMatch[0]);
            if (in_array($sRequestedLanguage, ['de', 'en', 'fr', 'it'], true)) $aParams['lang'] = $sRequestedLanguage;
        }
        try {
            $oClient = $this->clientService->newClient();
            $sUrl = 'https://photon.komoot.io/api?' . http_build_query($aParams, '', '&', PHP_QUERY_RFC3986);
            $oResponse = $oClient->get($sUrl, [
                'headers' => ['Accept' => 'application/geo+json, application/json', 'User-Agent' => 'HC-Navigation/' . Application::VERSION . ' (+https://github.com/hacesoft/Places-and-Navigation)'],
                'timeout' => 12,
            ]);
            $nStatus = $oResponse->getStatusCode();
            if ($nStatus < 200 || $nStatus >= 300) throw new \RuntimeException('Photon returned HTTP ' . $nStatus);
            $aData = json_decode($oResponse->getBody(), true, 512, JSON_THROW_ON_ERROR);
        } catch (\Throwable $oError) {
            $this->logger->warning('HC Navigation geocoding failed: {message}', ['app' => Application::APP_ID, 'message' => $oError->getMessage(), 'exception' => $oError]);
            return ['results' => [], 'error' => 'geocoding_unavailable', '_status' => 502];
        }
        $aResults = [];
        foreach (($aData['features'] ?? []) as $aFeature) {
            $aCoordinates = $aFeature['geometry']['coordinates'] ?? null;
            if (!is_array($aCoordinates) || count($aCoordinates) < 2 || !is_numeric($aCoordinates[0]) || !is_numeric($aCoordinates[1])) continue;
            $aProperties = $aFeature['properties'] ?? [];
            $sName = trim((string)($aProperties['name'] ?? $aProperties['street'] ?? $sQuery));
            $aParts = [];
            if (!empty($aProperties['housenumber']) && !empty($aProperties['street'])) $aParts[] = trim((string)$aProperties['street'] . ' ' . (string)$aProperties['housenumber']);
            elseif (!empty($aProperties['street']) && $aProperties['street'] !== $sName) $aParts[] = (string)$aProperties['street'];
            foreach (['district', 'city', 'county', 'state', 'postcode', 'country'] as $sKey) {
                if (!empty($aProperties[$sKey]) && !in_array((string)$aProperties[$sKey], $aParts, true) && (string)$aProperties[$sKey] !== $sName) $aParts[] = (string)$aProperties[$sKey];
            }
            $aResults[] = [
                'name' => $sName !== '' ? $sName : $sQuery,
                'label' => implode(', ', $aParts),
                'latitude' => (float)$aCoordinates[1],
                'longitude' => (float)$aCoordinates[0],
                'type' => (string)($aProperties['osm_value'] ?? $aProperties['osm_key'] ?? ''),
            ];
        }
        return ['results' => $aResults, 'provider' => 'Photon / OpenStreetMap'];
    }
}
