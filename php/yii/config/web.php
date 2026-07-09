<?php

return [
    'id'         => 'basic',
    'basePath'   => dirname(__DIR__),
    'bootstrap'  => ['log'],
    'aliases'    => [
        '@bower' => '@vendor/bower-asset',
        '@npm'   => '@vendor/npm-asset',
    ],
    'components' => [
        'request' => [
            'cookieValidationKey' => getenv('APP_SECRET') ?: 'change-me-in-production',
        ],
        'cache'     => ['class' => 'yii\caching\FileCache'],
        'log'       => [
            'traceLevel' => 0,
            'targets'    => [
                ['class' => 'yii\log\FileTarget', 'levels' => ['error', 'warning']],
            ],
        ],
        'db' => [
            'class'    => 'yii\db\Connection',
            'dsn'      => getenv('DATABASE_URL') ?: 'pgsql:host=localhost;dbname=app',
            'username' => getenv('DB_USER') ?: 'app',
            'password' => getenv('DB_PASSWORD') ?: '',
        ],
        'urlManager' => [
            'enablePrettyUrl'     => true,
            'showScriptName'      => false,
            'enableStrictParsing' => false,
            'rules'               => [
                'GET /'       => 'site/index',
                'GET /health' => 'site/health',
            ],
        ],
        'errorHandler' => ['errorAction' => 'site/error'],
    ],
    'params' => [],
];
