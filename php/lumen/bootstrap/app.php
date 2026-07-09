<?php

require_once __DIR__ . '/../vendor/autoload.php';

$app = new Laravel\Lumen\Application(dirname(__DIR__));

$app->withFacades();
$app->withEloquent();

$app->router->get('/health', function () {
    return response()->json(['status' => 'ok']);
});

$app->router->get('/', function () {
    return response()->json(['message' => 'Welcome to the API']);
});

return $app;
