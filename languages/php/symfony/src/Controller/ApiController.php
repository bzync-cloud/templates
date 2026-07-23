<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

class ApiController
{
    #[Route('/', methods: ['GET'])]
    public function index(): JsonResponse
    {
        return new JsonResponse(['message' => 'Welcome to the API']);
    }

    #[Route('/health', methods: ['GET'])]
    public function health(): JsonResponse
    {
        return new JsonResponse(['status' => 'ok']);
    }
}
