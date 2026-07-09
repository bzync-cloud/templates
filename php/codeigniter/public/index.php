<?php

declare(strict_types=1);

define('FCPATH', __DIR__ . DIRECTORY_SEPARATOR);

require FCPATH . '../app/Config/Paths.php';
$paths = new Config\Paths();

require rtrim($paths->systemDirectory, '\\/') . DIRECTORY_SEPARATOR . 'bootstrap.php';

$app = \Config\Services::codeigniter();
$app->initialize();
$context = is_cli() ? 'php-cli' : 'web';
$app->setContext($context);
$app->run();
