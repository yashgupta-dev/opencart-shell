<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Set up {{ config('app.name') }}</title>
<style>
:root{--ink:#17212b;--mute:#5b6b7a;--line:#d8dee4;--bg:#eef1f4;--card:#fff;--ok:#0b6e4f;--bad:#b42318}
body{margin:0;font:16px/1.5 system-ui,sans-serif;color:var(--ink);background:var(--bg)}
main{max-width:860px;margin:6vh auto;display:grid;grid-template-columns:230px 1fr;background:var(--card);border:1px solid var(--line);border-radius:6px;overflow:hidden}
nav{padding:28px 24px;border-right:1px solid var(--line)} nav h1{font-size:1rem;margin:0 0 24px}
ol{list-style:none;margin:0;padding:0;counter-reset:s}
li{counter-increment:s;position:relative;padding:0 0 22px 34px;color:var(--mute)}
li::before{content:counter(s);position:absolute;left:0;top:0;width:22px;height:22px;box-sizing:border-box;border-radius:50%;border:1.5px solid var(--line);font-size:.75rem;text-align:center;line-height:19px;background:var(--card)}
li::after{content:"";position:absolute;left:11px;top:24px;bottom:2px;width:1.5px;background:var(--line)}
li:last-child::after{display:none}
li.now{color:var(--ink);font-weight:600} li.now::before{border-color:var(--ok);color:var(--ok)}
li.done::before{content:"\2713";background:var(--ok);border-color:var(--ok);color:#fff} li.done::after{background:var(--ok)}
section{padding:32px 36px} h2{margin:0 0 4px;font-size:1.4rem} section>p{margin:0 0 8px;color:var(--mute)}
.field{margin:16px 0;display:grid;gap:4px} label{font-weight:600;font-size:.9rem} label.inline{font-weight:400;display:flex;gap:8px}
input,select{padding:9px 10px;border:1px solid var(--line);border-radius:4px;font:inherit}
small{color:var(--mute)} .err{color:var(--bad)} .alert{color:var(--bad);border:1px solid var(--bad);padding:10px 12px;border-radius:4px;margin:12px 0;white-space:pre-wrap}
.check{padding:8px 0;border-bottom:1px solid var(--line)} .check b{display:inline-block;width:3em} .ok b{color:var(--ok)} .bad b{color:var(--bad)}
button{margin-top:12px;background:var(--ok);color:#fff;border:0;padding:10px 18px;border-radius:4px;font:inherit;font-weight:600;cursor:pointer}
a.btn{display:inline-block;margin-top:12px;background:var(--ok);color:#fff;padding:10px 18px;border-radius:4px;font-weight:600;text-decoration:none}
:focus-visible{outline:2px solid var(--ok);outline-offset:2px}
@media(max-width:700px){main{grid-template-columns:1fr;margin:0;border:0} nav{border-right:0;border-bottom:1px solid var(--line)}}
</style>
</head>
<body>
<main>
    <nav aria-label="Setup progress">
        <h1>{{ config('app.name') }}</h1>
        <ol>
            @foreach ($steps as $key => $step)
                <li @class(['now' => empty($finished) && $key === $current->key(), 'done' => in_array($key, $done)])>{{ $step->title() }}</li>
            @endforeach
        </ol>
    </nav>
    <section>
        @if (! empty($finished))
            <h2>Setup complete</h2>
            <p>Your settings are saved to .env. The dev server may restart for a second, so reload if the page does not open.</p>
            <a class="btn" href="{{ $url }}">Open the app</a>
        @else
        <h2>{{ $current->title() }}</h2>
        <p>{{ $current->description() }}</p>
        @error('setup')<div class="alert" role="alert">{{ $message }}</div>@enderror
        <form method="post" action="{{ route('setup-wizard.store', $current->key()) }}">
            @csrf
            @foreach ($current->checks() as $check)
                <div @class(['check', 'ok' => $check['ok'], 'bad' => ! $check['ok']])>
                    <b>{{ $check['ok'] ? 'Pass' : 'Fix' }}</b>{{ $check['label'] }}
                    @unless ($check['ok'])<small>{{ $check['hint'] }}</small>@endunless
                </div>
            @endforeach
            @foreach ($current->fields() as $name => $field)
                @php($type = $field['type'] ?? 'text')
                <div class="field">
                    <label for="{{ $name }}">{{ $field['label'] }}</label>
                    @if ($type === 'select')
                        <select id="{{ $name }}" name="{{ $name }}">
                            @foreach ($field['options'] as $value => $label)
                                <option value="{{ $value }}" @selected(old($name, $field['default'] ?? '') == $value)>{{ $label }}</option>
                            @endforeach
                        </select>
                    @elseif ($type === 'checkboxes')
                        @foreach ($field['options'] as $value => $label)
                            <label class="inline"><input type="checkbox" name="{{ $name }}[]" value="{{ $value }}" @checked(in_array($value, old($name, $field['default'] ?? [])))> {{ $label }}</label>
                        @endforeach
                    @else
                        <input id="{{ $name }}" name="{{ $name }}" type="{{ $type }}" value="{{ $type === 'password' ? '' : old($name, $field['default'] ?? '') }}">
                    @endif
                    @error($name)<small class="err">{{ $message }}</small>@enderror
                    @isset($field['help'])<small>{{ $field['help'] }}</small>@endisset
                </div>
            @endforeach
            <button type="submit">{{ $current->action() }}</button>
        </form>
        @endif
    </section>
</main>
</body>
</html>
