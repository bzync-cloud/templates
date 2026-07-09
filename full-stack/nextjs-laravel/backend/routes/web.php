<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json(['message' => 'Laravel API backend running on Bzync Cloud']);
});

Route::get('/health', function () {
    return response()->json(['status' => 'ok']);
});
