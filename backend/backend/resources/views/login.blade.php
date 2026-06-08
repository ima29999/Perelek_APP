<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Perelek Digital</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f7fb; color: #2d373f; margin: 0; padding: 0; }
        .container { max-width: 420px; margin: 60px auto; background: #ffffff; border-radius: 12px; box-shadow: 0 16px 40px rgba(0,0,0,.08); padding: 32px; }
        h1 { margin: 0 0 24px; font-size: 24px; }
        label { display: block; margin-bottom: 8px; font-weight: 600; }
        input { width: 100%; padding: 12px 14px; margin-bottom: 18px; border: 1px solid #dfe3ea; border-radius: 10px; }
        button { width: 100%; background: #3b82f6; color: white; border: none; padding: 14px; border-radius: 10px; cursor: pointer; font-size: 16px; }
        button:hover { background: #2563eb; }
        .message { margin-bottom: 18px; padding: 14px 18px; border-radius: 10px; }
        .success { background: #ecfdf5; color: #166534; }
        .error { background: #fce7e7; color: #991b1b; }
        .token { word-break: break-all; background: #f1f5f9; padding: 12px 14px; border-radius: 10px; margin-top: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Login Backend Perelek</h1>

        @if ($errors->any())
            <div class="message error">
                <strong>Gagal login</strong>
                <ul style="margin: 8px 0 0 0;padding-left:20px;">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        @if (session('status'))
            <div class="message success">{{ session('status') }}</div>
        @endif

        <form action="/login" method="post">
            @csrf
            <label for="identifier">Email / Nomor HP</label>
            <input type="text" id="identifier" name="identifier" value="{{ old('identifier') }}" placeholder="admin@perelek.local atau 081..." required>

            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="Password" required>

            <button type="submit">Login</button>
        </form>

        @if (session('token'))
            <div class="token">
                <strong>Token API:</strong>
                <div>{{ session('token') }}</div>
            </div>
        @endif

        <div style="margin-top: 22px; font-size: 14px; color: #667085;">
            <p>Gunakan token ini untuk memanggil endpoint API dengan header:</p>
            <code>Authorization: Bearer &lt;token&gt;</code>
        </div>
    </div>
</body>
</html>
