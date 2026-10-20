<?php

declare(strict_types=1);
namespace OCA\HcNavigation\Service;

use OCP\IGroupManager;
use OCP\IUserManager;
use OCP\IUserSession;

class PickerService {
    public function __construct(private IUserManager $userManager, private IGroupManager $groupManager, private IUserSession $userSession) {}

    public function search(string $sQuery, array $aTypes): array {
        $sQuery = trim($sQuery);
        $aAllowed = array_values(array_intersect($aTypes, ['user', 'group']));
        if ($aAllowed === []) $aAllowed = ['user', 'group'];
        $aItems = [];
        $sCurrentUid = $this->userSession->getUser()?->getUID() ?? '';
        if (in_array('user', $aAllowed, true)) {
            foreach ($this->userManager->search($sQuery, 20, 0) as $oUser) {
                if ($oUser->getUID() === $sCurrentUid) continue;
                $sLabel = trim((string)$oUser->getDisplayName());
                $aItems[] = ['id' => $oUser->getUID(), 'label' => $sLabel !== '' ? $sLabel : $oUser->getUID(), 'type' => 'user'];
            }
        }
        if (in_array('group', $aAllowed, true)) {
            foreach ($this->groupManager->search($sQuery, 20, 0) as $oGroup) {
                $aItems[] = ['id' => $oGroup->getGID(), 'label' => $oGroup->getDisplayName(), 'type' => 'group'];
            }
        }
        usort($aItems, static fn(array $a, array $b): int => strcasecmp($a['label'], $b['label']));
        return array_slice($aItems, 0, 30);
    }
}
