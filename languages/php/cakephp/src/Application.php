<?php

declare(strict_types=1);

namespace App;

use Cake\Core\BasePlugin;
use Cake\Core\Configure;
use Cake\Core\ContainerInterface;
use Cake\Http\BaseApplication;
use Cake\Http\MiddlewareQueue;
use Cake\Routing\Middleware\RoutingMiddleware;

class Application extends BaseApplication
{
    public function bootstrap(): void
    {
        parent::bootstrap();
    }

    public function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue
    {
        $middlewareQueue->add(new RoutingMiddleware($this));
        return $middlewareQueue;
    }

    public function routes(\Cake\Routing\RouteBuilder $routes): void
    {
        $routes->scope('/', function (\Cake\Routing\RouteBuilder $builder) {
            $builder->connect('/', ['controller' => 'Pages', 'action' => 'index']);
            $builder->connect('/health', ['controller' => 'Pages', 'action' => 'health']);
        });
    }

    public function services(ContainerInterface $container): void {}
}
