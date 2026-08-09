<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

class GroqService
{
    protected Client $http;
    protected string $apiKey;
    protected string $model;

    public function __construct()
    {
        // Memastikan config terbaca dengan benar
        $this->apiKey = (string) config('services.groq.api_key');
        $this->model  = (string) config('services.groq.model', 'llama3-8b-8192');

        $this->http = new Client([
            'timeout'  => 30,
        ]);
    }

    public function generateReply(string $systemInstruction, array $history, string $userMessage): string
    {
        if (empty($this->apiKey)) {
            Log::error('Groq API Key kosong di config services.');
            throw new \RuntimeException('GROQ_API_KEY belum diatur di file .env backend.');
        }

        // Susun messages sesuai standar Groq / OpenAI
        $messages = [
            ['role' => 'system', 'content' => $systemInstruction],
        ];

        foreach ($history as $item) {
            $role = $item['role'] ?? 'user';
            $content = trim((string) ($item['content'] ?? ''));
            
            if ($content === '') {
                continue;
            }
            $messages[] = ['role' => $role, 'content' => $content];
        }

        $messages[] = ['role' => 'user', 'content' => $userMessage];

        // DEBUG: Mari intip apa yang dikirim Laravel ke Groq (Lihat di storage/logs/laravel.log)
        Log::info('Payload dikirim ke Groq:', [
            'model' => $this->model,
            'messages' => $messages
        ]);

        try {
            // Gunakan full URL langsung di method POST untuk menghindari masalah routing proxy
            $response = $this->http->post('https://api.groq.com/openai/v1/chat/completions', [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Content-Type'  => 'application/json',
                    'Accept'        => 'application/json',
                ],
                'verify' => false,
                'json' => [
                    'model'       => $this->model,
                    'messages'    => $messages,
                    'temperature' => 0.4,
                    'max_tokens'  => 800,
                ],
            ]);

            $body = json_decode((string) $response->getBody(), true);
            $text = $body['choices'][0]['message']['content'] ?? null;

            if (!$text) {
                $finishReason = $body['choices'][0]['finish_reason'] ?? null;
                if ($finishReason === 'content_filter') {
                    return 'Maaf, saya tidak bisa menjawab pertanyaan itu. Coba tanyakan hal lain seputar iuran atau aplikasi Perelek ya.';
                }
                throw new \RuntimeException('Respons Groq kosong/tidak terduga.');
            }

            return trim($text);
        } catch (\GuzzleHttp\Exception\RequestException $e) {
            $errorBody = $e->getResponse()
                ? (string) $e->getResponse()->getBody()
                : $e->getMessage();

            // Ini akan mencatat error asli dari Groq ke laravel.log
            Log::error('Groq generateReply gagal total', ['error' => $errorBody]);

            throw new \RuntimeException('Gagal menghubungi Groq API: ' . $errorBody);
        }
    }
}