<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('about', function () {
    $this->comment('Bzync Cloud Laravel Inertia Svelte starter');
})->purpose('Display starter information');
