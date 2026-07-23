<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

class App extends BaseConfig
{
    public string $baseURL    = '';
    public string $appTimezone = 'UTC';
    public string $defaultLocale = 'en';
    public bool   $negotiateLocale = false;
    public array  $supportedLocales = ['en'];
    public string $charset  = 'UTF-8';
    public bool   $forceGlobalSecureRequests = false;
    public string $proxyIPs = '';
    public string $CSPEnabled = 'false';
}
