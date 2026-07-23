<?php

use Cake\Cache\Cache;
use Cake\Core\Configure;
use Cake\Core\Configure\Engine\PhpConfig;
use Cake\Datasource\ConnectionManager;
use Cake\Log\Log;
use Cake\Utility\Security;

try {
    Configure::config('default', new PhpConfig());
    Configure::load('app', 'default', false);
} catch (\Exception $e) {
    exit($e->getMessage() . "\n");
}

if (!Configure::read('debug')) {
    ini_set('display_errors', '0');
}

Configure::write('App.fullBaseUrl', 'http://localhost');

date_default_timezone_set('UTC');
mb_internal_encoding('UTF-8');

Cache::setConfig(Configure::consume('Cache'));
ConnectionManager::setConfig(Configure::consume('Datasources'));
Security::setSalt(Configure::consume('Security.salt'));
