<?php

namespace App\Controllers;

use CodeIgniter\HTTP\ResponseInterface;

class Home extends BaseController
{
    public function index(): ResponseInterface
    {
        return $this->response
            ->setContentType('application/json')
            ->setJSON(['message' => 'Welcome to the API']);
    }

    public function health(): ResponseInterface
    {
        return $this->response
            ->setContentType('application/json')
            ->setJSON(['status' => 'ok']);
    }
}
