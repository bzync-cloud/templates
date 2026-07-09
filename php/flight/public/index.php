<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

Flight::route('GET /health', function () {
    Flight::json(['status' => 'ok']);
});

Flight::route('GET /', function () {
    Flight::json(['message' => 'Welcome to the API']);
});

Flight::start();
