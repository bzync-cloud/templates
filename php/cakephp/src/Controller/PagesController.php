<?php

declare(strict_types=1);

namespace App\Controller;

use Cake\Controller\Controller;

class PagesController extends Controller
{
    public function index(): \Cake\Http\Response
    {
        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode(['message' => 'Welcome to the API']));
    }

    public function health(): \Cake\Http\Response
    {
        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode(['status' => 'ok']));
    }
}
