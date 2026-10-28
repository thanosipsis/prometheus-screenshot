#!/usr/bin/env python3
"""Freeze the focused display before showing the capture controls."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp'))
    with (runtime / f'prometheus-screenshot-{os.getuid()}.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        monitors = json.loads(subprocess.check_output(['hyprctl', '-j', 'monitors']))
        monitor = next(m for m in monitors if m['focused'])
        windows = json.loads(subprocess.check_output(['hyprctl', '-j', 'clients']))
        with tempfile.TemporaryDirectory(prefix='prometheus-screenshot-', dir=runtime) as folder:
            image = str(Path(folder) / 'screen.png')
            subprocess.run(['grim', '-o', monitor['name'], image], check=True)
            context = {'monitor': monitor, 'windows': windows, 'image': image}
            env = dict(os.environ, PROMETHEUS_CAPTURE_CONTEXT=json.dumps(context))
            subprocess.run(['quickshell', '-p', str(Path(__file__).resolve().parent), '-n'], env=env, check=True)
            result = Path(folder) / 'result.png'
            if result.exists():
                subprocess.run(['wl-copy', '--type', 'image/png'], input=result.read_bytes(), check=True, start_new_session=True)
                output = json.loads(result.with_suffix('.json').read_text())['output']
                detail = f'Saved and copied to clipboard\n{output}' if output else 'Copied to clipboard'
                subprocess.run(['notify-send', 'Screenshot captured', detail], check=False)


if __name__ == '__main__':
    try:
        main()
    except (subprocess.CalledProcessError, OSError, StopIteration, ValueError) as error:
        subprocess.run(['notify-send', '-u', 'critical', 'Screenshot failed', str(error)], check=False)
        raise SystemExit(1)
