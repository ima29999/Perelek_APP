<?php

namespace App\Http\Controllers;

use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $events = Event::where('is_active', true)
            ->orderBy('event_date')
            ->paginate(50);

        return response()->json($events);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'location' => 'required|string|max:255',
            'event_date' => 'required|date',
            'event_time' => 'nullable|string|max:32',
            'notify_h1' => 'boolean',
            'notify_h0' => 'boolean',
            'is_active' => 'boolean',
        ]);

        $data['created_by'] = $request->user()->id;
        $data['notify_h1'] = $request->boolean('notify_h1', true);
        $data['notify_h0'] = $request->boolean('notify_h0', true);
        $data['is_active'] = $request->boolean('is_active', true);

        $event = Event::create($data);

        return response()->json($event, 201);
    }

    public function show(Event $event): JsonResponse
    {
        return response()->json($event);
    }

    public function update(Request $request, Event $event): JsonResponse
    {
        $data = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'location' => 'sometimes|required|string|max:255',
            'event_date' => 'sometimes|required|date',
            'event_time' => 'sometimes|nullable|string|max:32',
            'notify_h1' => 'sometimes|boolean',
            'notify_h0' => 'sometimes|boolean',
            'is_active' => 'sometimes|boolean',
        ]);

        $event->update($data);

        return response()->json($event);
    }

    public function destroy(Event $event): JsonResponse
    {
        $event->delete();

        return response()->json(['message' => 'Kegiatan berhasil dibatalkan.']);
    }
}
