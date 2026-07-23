<?php

return [
    'debug' => filter_var(env('DEBUG', false), FILTER_VALIDATE_BOOLEAN),
    'App' => [
        'namespace' => 'App',
        'encoding' => 'UTF-8',
        'defaultLocale' => 'en_US',
        'defaultTimezone' => 'UTC',
        'base' => false,
        'dir' => 'src',
        'webroot' => 'webroot',
        'wwwRoot' => WWW_ROOT,
        'fullBaseUrl' => false,
        'imageBaseUrl' => 'img/',
        'cssBaseUrl' => 'css/',
        'jsBaseUrl' => 'js/',
        'paths' => [
            'plugins' => [ROOT . DS . 'plugins' . DS],
            'templates' => [APP . 'templates' . DS],
            'locales' => [APP . 'Locale' . DS],
        ],
    ],
    'Security' => ['salt' => env('SECURITY_SALT', 'change-me-in-production')],
    'Datasources' => [
        'default' => [
            'className' => \Cake\Database\Connection::class,
            'driver'    => \Cake\Database\Driver\Postgres::class,
            'url'       => env('DATABASE_URL', null),
            'timezone'  => 'UTC',
        ],
    ],
    'Cache' => [
        'default' => ['className' => \Cake\Cache\Engine\FileEngine::class, 'path' => CACHE],
        '_cake_core_' => ['className' => \Cake\Cache\Engine\FileEngine::class, 'prefix' => 'cake_core_', 'path' => CACHE . 'persistent' . DS],
        '_cake_model_' => ['className' => \Cake\Cache\Engine\FileEngine::class, 'prefix' => 'cake_model_', 'path' => CACHE . 'models' . DS],
    ],
    'Log' => [
        'debug' => ['className' => \Cake\Log\Engine\FileLog::class, 'path' => LOGS, 'file' => 'debug', 'url' => env('LOG_DEBUG_URL', null), 'levels' => ['notice', 'info', 'debug']],
        'error' => ['className' => \Cake\Log\Engine\FileLog::class, 'path' => LOGS, 'file' => 'error', 'url' => env('LOG_ERROR_URL', null), 'levels' => ['warning', 'error', 'critical', 'alert', 'emergency']],
    ],
    'Error' => ['errorLevel' => E_ALL, 'skipLog' => [], 'log' => true, 'trace' => true],
];
