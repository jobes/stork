#!/usr/bin/env python3
"""Run local Flutter screenshot comparisons and build a standalone gallery."""
import argparse
import base64
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SCREENS = {
    'drawer': ('Map menu', 'Active route and offline map download date'),
    'settings': ('Settings overview', 'Settings menu'),
    'gateway': ('Instruments and connection', 'Gateway and DroneCAN instruments'),
    'map': ('Map settings', 'Top of page'),
    'map_bottom': ('Map settings', 'Bottom of page'),
    'map_reset': ('Map settings', 'Reset widget positions dialog'),
    'flight': ('Units and limits', 'Top of page'),
    'flight_bottom': ('Units and limits', 'Bottom of page'),
    'traffic': ('Traffic and alerts', 'Top of page'),
    'traffic_bottom': ('Traffic and alerts', 'Bottom of page'),
    'map_widgets': ('Map widgets', 'Flight, engine and radio'),
    'map_widgets_no_data': ('Map widgets', 'Missing sensor data'),
    'map_widgets_large': ('Map widgets', 'Enlarged flight instruments'),
    'telemetry': ('Telemetry', 'Normal, warning and critical states'),
    'collision': ('Collision warning', 'Default map text size'),
    'collision_large': ('Collision warning', 'Largest map text size'),
}
DEVICES = {
    'phone_portrait': 'Phone · Portrait',
    'phone_landscape': 'Phone · Landscape',
    'tablet_portrait': 'Tablet · Portrait',
    'tablet_landscape': 'Tablet · Landscape',
}
THEMES = {'light': 'Light', 'dark': 'Dark'}
SCREENSHOT_NAME = re.compile(
    r'(.+)_(phone|tablet)_(portrait|landscape)_en_(light|dark)'
)


def screenshot_order(path):
    match = SCREENSHOT_NAME.fullmatch(path.stem)
    if match is None:
        return (len(SCREENS), 0, 0, path.stem)
    view, device, orientation, theme = match.groups()
    return (
        list(SCREENS).index(view) if view in SCREENS else len(SCREENS),
        list(DEVICES).index(f'{device}_{orientation}'),
        list(THEMES).index(theme),
        path.stem,
    )


def image(path):
    if not path.exists():
        return '<p>No image available.</p>'
    uri = 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()
    name = html.escape(path.stem)
    return (
        '<label class="screenshot">'
        f'<input class="zoom-toggle" type="checkbox" aria-label="Enlarge {name}">'
        '<span class="screenshot-view">'
        f'<img src="{uri}" alt="{name}" loading="lazy">'
        '<span class="zoom-close" aria-hidden="true">Close ×</span>'
        '</span></label>'
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', nargs='?', choices=['check', 'update'], default='check')
    parser.add_argument('--flutter', default=os.environ.get('FLUTTER_BIN'))
    parser.add_argument('--report-dir', type=Path, default=ROOT / 'build/visual-tests')
    args = parser.parse_args()
    flutter = args.flutter or ('/opt/flutter/bin/flutter' if Path('/opt/flutter/bin/flutter').exists() else shutil.which('flutter'))
    if not flutter:
        parser.error('Flutter not found; pass --flutter /path/to/flutter.')
    report = args.report_dir.resolve()
    current = report / 'current'
    current.mkdir(parents=True, exist_ok=True)
    # Clear only known generated captures, so a failed run cannot show stale ones.
    for path in current.glob('*.png'):
        path.unlink()
    failures = ROOT / 'test/visual/failures'
    if failures.exists():
        for path in failures.glob('*.png'):
            path.unlink()
    env = dict(os.environ, STORK_VISUAL_REPORT_DIR=str(report))
    version = subprocess.run([flutter, '--version', '--machine'], cwd=ROOT, env=env, capture_output=True, text=True, check=True)
    metadata = json.loads(version.stdout)
    command = [flutter, 'test', '--no-pub', '--concurrency=1', 'test/visual/stork_visual_test.dart']
    if args.mode == 'update':
        command.append('--update-goldens')
    print('Updating local reference screenshots.' if args.mode == 'update' else 'Comparing with local reference screenshots.', flush=True)
    with (report / 'test.log').open('w') as log:
        result = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
    baselines = ROOT / 'test/visual/goldens'
    groups = {}
    for baseline in sorted(baselines.glob('*.png'), key=screenshot_order):
        match = SCREENSHOT_NAME.fullmatch(baseline.stem)
        if match:
            view, device, orientation, theme = match.groups()
            screen, position = SCREENS.get(view, ('Other screenshots', view))
            device_label = DEVICES[f'{device}_{orientation}']
            variant = THEMES[theme]
        else:
            screen, position = 'Other screenshots', 'Unclassified'
            device_label, variant = baseline.stem, ''
        actual = current / baseline.name
        diffs = sorted(p for p in failures.glob(f'{baseline.stem}_*.png') if 'diff' in p.name.lower()) if failures.exists() else []
        state = 'Missing capture' if not actual.exists() else ('Difference' if diffs else ('New reference — review it' if args.mode == 'update' else 'Match'))
        if state == 'Match' or args.mode == 'update':
            pictures = f'<figure><figcaption>Current screenshot</figcaption>{image(actual)}</figure>'
        else:
            pictures = f'<div class="pair"><figure><figcaption>Reference</figcaption>{image(baseline)}</figure><figure><figcaption>Current</figcaption>{image(actual)}</figure></div>'
        differences = ''.join(
            f'<details><summary>{html.escape(p.name)}</summary>{image(p)}</details>'
            for p in diffs
        )
        search = f'{baseline.stem} {screen} {position} {device_label} {variant} {state}'
        card = (
            f'<article data-search="{html.escape(search.lower())}">'
            f'<h4>{html.escape(device_label)}</h4>'
            f'<p>{html.escape(variant)} · {state}</p>{pictures}{differences}</article>'
        )
        groups.setdefault(screen, {}).setdefault(position, []).append(card)

    sections = []
    for screen, views in groups.items():
        sections.append(f'<section class="screen-group"><h2>{html.escape(screen)}</h2>')
        for position, cards in views.items():
            sections.append(
                f'<div class="view-group"><h3>{html.escape(position)}</h3>'
                '<div class="gallery-grid">' + ''.join(cards) + '</div></div>'
            )
        sections.append('</section>')

    status = 'PASSED' if result.returncode == 0 else 'FAILED — inspect test.log'
    document = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Stork visual tests</title><style>
body{font:16px system-ui;margin:24px;background:#111c25;color:#eaf2f7}h1{margin-bottom:8px}input{padding:12px;width:min(90%,450px);margin:16px 0}.gallery-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,320px),1fr));gap:16px;align-items:start}.screen-group{margin:24px 0 40px}.screen-group h2{border-bottom:1px solid #394d59;padding-bottom:8px}.view-group{margin:16px 0 28px}.view-group h3{color:#abbfcb;font-size:16px}article h4{margin:0;font-size:16px}[hidden]{display:none!important}article{background:#1a2934;padding:16px;border:1px solid #394d59;border-radius:14px}.pair{display:flex;gap:12px}figure{margin:0;min-width:0;flex:1}
.screenshot{display:block;cursor:zoom-in}
.zoom-toggle{position:absolute;width:1px;height:1px;margin:0;padding:0;opacity:0}
.screenshot-view{display:block}
.screenshot img{display:block;width:100%;height:auto}
.zoom-toggle:focus-visible + .screenshot-view{outline:2px solid #80cee4;outline-offset:4px}
.zoom-close{display:none}
.zoom-toggle:checked + .screenshot-view{
    position:fixed;inset:0;z-index:10;box-sizing:border-box;
    display:grid;place-items:center;padding:48px 16px 16px;
    background:#000e;cursor:zoom-out
}
.zoom-toggle:checked + .screenshot-view img{
    width:auto;max-width:100%;max-height:100%;min-height:0;object-fit:contain
}
.zoom-toggle:checked + .screenshot-view .zoom-close{
    display:block;position:absolute;top:12px;right:16px;
    padding:6px 12px;border-radius:6px;background:#1a2934;color:#eaf2f7
}

body:has(#zoom-controls:not([hidden])) .zoom-toggle:checked + .screenshot-view{
    padding-bottom:72px
}
#zoom-controls{
    position:fixed;z-index:11;bottom:12px;left:50%;transform:translateX(-50%);
    display:flex;align-items:center;gap:12px;padding:6px;
    border:1px solid #394d59;border-radius:10px;background:#1a2934
}
#zoom-controls button{
    min-width:44px;min-height:44px;border:1px solid #394d59;
    border-radius:6px;background:#223644;color:#eaf2f7;font-size:22px;cursor:pointer
}
#zoom-controls button:disabled{opacity:.45;cursor:default}
#zoom-position{min-width:7ch;text-align:center;white-space:nowrap}
figcaption{margin:8px 0;color:#abbfcb}details{margin-top:12px}a{color:#80cee4}</style>'''
    document += f'<h1>Stork visual tests</h1><p>{status} · {args.mode} · {len(list(current.glob("*.png")))} captures</p><p>Flutter {html.escape(metadata.get("frameworkVersion", "unknown"))} · {html.escape(sys.platform)} · phone 412 × 892 / 892 × 412 · tablet 800 × 1280 / 1280 × 800 · English · fixed demo data</p><p>Widget screenshots; no live map, GPS or Android device capture. Reference images require your visual review.</p><input id="filter" aria-label="Filter screenshots" placeholder="Filter: map, tablet, en_dark…"><main>'
    document += ''.join(sections) + r'''</main>
<div id="zoom-controls" role="group" aria-label="Screenshot navigation" hidden>
    <button type="button" id="zoom-previous" aria-label="Previous screenshot" title="Previous (←)">←</button>
    <span id="zoom-position" aria-live="polite"></span>
    <button type="button" id="zoom-next" aria-label="Next screenshot" title="Next (→)">→</button>
</div>
<script>
const controls = document.querySelector("#zoom-controls");
const previous = document.querySelector("#zoom-previous");
const next = document.querySelector("#zoom-next");
const position = document.querySelector("#zoom-position");
let activeScreenshot = null;

function visibleScreenshots() {
    return Array.from(document.querySelectorAll(".zoom-toggle"))
        .filter(toggle => toggle.getClientRects().length > 0);
}

function showScreenshot(toggle) {
    if (activeScreenshot) activeScreenshot.checked = false;
    activeScreenshot = toggle;
    controls.hidden = !toggle;
    if (!toggle) return;
    toggle.checked = true;
    toggle.nextElementSibling.querySelector("img").loading = "eager";
    const screenshots = visibleScreenshots();
    position.textContent = (screenshots.indexOf(toggle) + 1) + " / " + screenshots.length;
    previous.disabled = next.disabled = screenshots.length < 2;
}

function stepScreenshot(direction) {
    if (!activeScreenshot) return;
    const screenshots = visibleScreenshots();
    const index = screenshots.indexOf(activeScreenshot);
    if (index < 0 || screenshots.length < 2) return;
    const target = screenshots[(index + direction + screenshots.length) % screenshots.length];
    const focusWasOnScreenshot = document.activeElement === activeScreenshot;
    showScreenshot(target);
    if (focusWasOnScreenshot) target.focus({ preventScroll: true });
}

document.querySelector("main").addEventListener("change", event => {
    const toggle = event.target;
    if (toggle.matches(".zoom-toggle")) showScreenshot(toggle.checked ? toggle : null);
});
previous.addEventListener("click", () => stepScreenshot(-1));
next.addEventListener("click", () => stepScreenshot(1));
document.addEventListener("keydown", event => {
    if (!activeScreenshot || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    switch (event.key) {
        case "ArrowLeft":
            stepScreenshot(-1);
            break;
        case "ArrowRight":
            stepScreenshot(1);
            break;
        case "Escape": {
            const toggle = activeScreenshot;
            showScreenshot(null);
            toggle.focus({ preventScroll: true });
            break;
        }
        default:
            return;
    }
    event.preventDefault();
});

document.querySelector("#filter").addEventListener("input", event => {
    const terms = event.target.value.trim().toLowerCase().split(/\s+/);
    for (const card of document.querySelectorAll("article")) {
        card.hidden = !terms.every(term => card.dataset.search.includes(term));
    }
    for (const group of document.querySelectorAll(".view-group, .screen-group")) {
        group.hidden = !group.querySelector("article:not([hidden])");
    }
    if (activeScreenshot) {
        showScreenshot(visibleScreenshots().includes(activeScreenshot) ? activeScreenshot : null);
    }
});
</script></html>'''
    (report / 'index.html').write_text(document)
    (report / 'environment.json').write_text(json.dumps(metadata, indent=2))
    print((report / 'test.log').read_text()[-2500:])
    print(f'Gallery: {report / "index.html"}')
    return result.returncode


if __name__ == '__main__':
    sys.exit(main())
