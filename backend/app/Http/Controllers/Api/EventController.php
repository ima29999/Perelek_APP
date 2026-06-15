<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::with('creator:id,name');

        // Filter bulan/tahun
        if ($month = $request->get('month')) {
            $query->whereMonth('start_date', $month);
        }
        if ($year = $request->get('year')) {
            $query->whereYear('start_date', $year);
        }

        // Filter upcoming
        if ($request->get('upcoming')) {
            $query->where('start_date', '>=', now());
        }

        $events = $query->orderBy('start_date')->get();

        return response()->json([
            'success' => true,
            'data'    => $events,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'location'    => 'nullable|string|max:255',
            'start_date'  => 'required|date',
            'end_date'    => 'nullable|date|after_or_equal:start_date',
            'color'       => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $event = Event::create([
            'title'       => $request->title,
            'description' => $request->description,
            'location'    => $request->location,
            'start_date'  => $request->start_date,
            'end_date'    => $request->end_date,
            'color'       => $request->get('color', '#3B82F6'),
            'created_by'  => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil ditambahkan.',
            'data'    => $event->load('creator:id,name'),
        ], 201);
    }

    public function show(Event $event)
    {
        return response()->json([
            'success' => true,
            'data'    => $event->load('creator:id,name'),
        ]);
    }

    public function update(Request $request, Event $event)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'location'    => 'nullable|string|max:255',
            'start_date'  => 'sometimes|date',
            'end_date'    => 'nullable|date',
            'color'       => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $event->update($request->only('title', 'description', 'location', 'start_date', 'end_date', 'color'));

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil diperbarui.',
            'data'    => $event->fresh()->load('creator:id,name'),
        ]);
    }

    public function destroy(Event $event)
    {
        $event->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil dihapus.',
        ]);
    }
}
