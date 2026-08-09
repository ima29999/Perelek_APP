<?php

// ─────────────────────────────────────────────────────────────────────────────
// INTEGRASI NOTIFIKASI DI InvoiceController.php yang sudah ada
// Tambahkan: use App\Helpers\NotifHelper;
// ─────────────────────────────────────────────────────────────────────────────

// Di method store() — setelah Invoice::create():

// $invoice = Invoice::create([...]);
// if ($invoice->is_active) {
//     NotifHelper::broadcast(
//         type:  NotifHelper::TYPE_INVOICE,
//         title: '🧾 Tagihan Baru',
//         body:  "Tagihan \"{$invoice->title}\" telah diterbitkan." .
//                ($invoice->deadline ? " Jatuh tempo: {$invoice->deadline->format('d/m/Y')}." : ''),
//         data:  ['invoice_id' => $invoice->id],
//     );
// }

// ─────────────────────────────────────────────────────────────────────────────
// INTEGRASI NOTIFIKASI DI EventController.php yang sudah ada
// Tambahkan: use App\Helpers\NotifHelper;
// ─────────────────────────────────────────────────────────────────────────────

// Di method store() — setelah Event::create():

// $event = Event::create([...]);
// NotifHelper::broadcast(
//     type:  NotifHelper::TYPE_EVENT,
//     title: "📅 Kegiatan: {$event->title}",
//     body:  "Kegiatan baru dijadwalkan pada " .
//            \Carbon\Carbon::parse($event->start_date)->translatedFormat('d F Y') .
//            ($event->location ? " di {$event->location}." : '.'),
//     data:  ['event_id' => $event->id],
// );
