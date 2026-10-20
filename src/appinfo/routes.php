<?php
return [
    'routes' => [
        ['name' => 'page#index', 'url' => '/', 'verb' => 'GET'],
        ['name' => 'geocoding#search', 'url' => '/api/geocoding/search', 'verb' => 'GET'],
        ['name' => 'picker#search', 'url' => '/api/picker', 'verb' => 'GET'],
        ['name' => 'settings#get', 'url' => '/api/settings', 'verb' => 'GET'],
        ['name' => 'settings#save', 'url' => '/api/settings', 'verb' => 'PUT'],
    ],
];
