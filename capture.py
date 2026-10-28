#!/usr/bin/env python3
"""Crop the frozen image, optionally save it, and hand it back to the launcher."""
import datetime
import os
import json
from pathlib import Path
import subprocess
import sys
import tempfile


def capture(source, x, y, width, height, screen_width, screen_height, save):
    x, y, width, height, screen_width, screen_height = map(float, (x, y, width, height, screen_width, screen_height))
    pixels = subprocess.check_output(['magick', 'identify', '-format', '%w %h', source], text=True)
    pixel_width, pixel_height = map(int, pixels.split())
    left = max(0, min(pixel_width, round(x * pixel_width / screen_width)))
    top = max(0, min(pixel_height, round(y * pixel_height / screen_height)))
    right = max(left, min(pixel_width, round((x + width) * pixel_width / screen_width)))
    bottom = max(top, min(pixel_height, round((y + height) * pixel_height / screen_height)))
    if right <= left or bottom <= top:
        raise ValueError('The selected area is empty.')
    with tempfile.TemporaryDirectory(prefix='prometheus-crop-') as folder:
        crop = Path(folder) / 'capture.png'
        subprocess.run(['magick', source, '-crop', f'{right-left}x{bottom-top}+{left}+{top}', '+repage', str(crop)], check=True)
        output = None
        if save == 'true':
            directory = Path(os.environ.get('PROMETHEUS_SCREENSHOT_DIR') or os.environ.get('HQS_DIR') or str(Path.home() / 'Pictures/Screenshots'))
            directory.mkdir(parents=True, exist_ok=True)
            output = directory / ('screenshot-' + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S-%f') + '.png')
            output.write_bytes(crop.read_bytes())
        # The launcher owns clipboard transfer after Quickshell exits. Its helper
        # processes must survive Quickshell's process-tree cleanup.
        result = Path(source).parent / 'result.png'
        result.write_bytes(crop.read_bytes())
        result.with_suffix('.json').write_text(json.dumps({'output': str(output) if output else None}))


if __name__ == '__main__':
    try:
        capture(*sys.argv[1:])
    except (subprocess.CalledProcessError, OSError, ValueError) as error:
        subprocess.run(['notify-send', '-u', 'critical', 'Screenshot failed', str(error)], check=False)
        print(error, file=sys.stderr)
        raise SystemExit(1)
