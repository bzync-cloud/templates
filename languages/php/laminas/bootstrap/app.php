<?php

declare(strict_types=1);

use Laminas\Diactoros\Response\JsonResponse;
use Laminas\Diactoros\ServerRequestFactory;
use Laminas\HttpHandlerRunner\Emitter\SapiEmitter;

require __DIR__ . '/../vendor/autoload.php';

class App
{
    public function run(): void
    {
        $request = ServerRequestFactory::fromGlobals();
        $path    = $request->getUri()->getPath();
        $method  = $request->getMethod();

        $response = match (true) {
            $method === 'GET' && $path === '/health' => new JsonResponse(['status' => 'ok']),
            $method === 'GET' && $path === '/'       => new JsonResponse(['message' => 'Welcome to the API']),
            default                                  => new JsonResponse(['error' => 'Not Found'], 404),
        };

        (new SapiEmitter())->emit($response);
    }
}

return new App();
