<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'midtrans' => [
        'server_key'     => env('MIDTRANS_SERVER_KEY'),
        'client_key'     => env('MIDTRANS_CLIENT_KEY'),
        'is_production'  => env('MIDTRANS_IS_PRODUCTION', false),
        // URL yang dideteksi & "ditangkap" oleh WebView di aplikasi Flutter
        // begitu transaksi Snap selesai/dibatalkan/error, supaya app tahu
        // kapan harus menutup WebView dan mengecek status terbaru.
        'finish_url' => env('MIDTRANS_FINISH_URL', 'http://localhost:8000/payment/finish'),
    'unfinish_url' => env('MIDTRANS_UNFINISH_URL', 'http://localhost:8000/payment/unfinish'),
    'error_url' => env('MIDTRANS_ERROR_URL', 'http://localhost:8000/payment/error'),
    ],

    'groq' => [
        'api_key' => env('GROQ_API_KEY'),
        'model'   => env('GROQ_MODEL', 'llama3-8b-8192'),
    ],

];
