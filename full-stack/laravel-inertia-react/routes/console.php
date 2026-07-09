<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('about', function () {
    $this->comment('Bzync Cloud Laravel Inertia React starter');
})->purpose('Display starter information');
