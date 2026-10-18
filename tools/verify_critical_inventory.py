"""Verify real inventory drops in disposable OpenMW interior/exterior profiles."""
from pathlib import Path
import argparse
import shutil
import subprocess
from build_arcane_misfires import ROOT, MOD, build


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine-root', type=Path, required=True)
    parser.add_argument('--game-data', type=Path, required=True)
    args = parser.parse_args()
    version = (args.engine_root/'resources/version').read_text(encoding='utf-8').strip()
    if not version.startswith('0.52.'):
        raise SystemExit(f'Use the tested OpenMW 0.52 engine, not {version}.')
    print(f'OpenMW {version}; disposable critical inventory checks')
    active = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq openmw.exe', '/NH'],
                            capture_output=True, text=True, check=True)
    if 'openmw.exe' in active.stdout.lower():
        raise SystemExit('Close existing OpenMW sessions before testing.')
    build()
    for name, start in (('interior', "Seyda Neen, Arrille's Tradehouse"), ('exterior', 'Seyda Neen')):
        output = ROOT/'.runtime'/f'critical-drop-{name}'
        output.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT/'tests/arcane_engine/settings.cfg', output/'settings.cfg')
        command = [str(args.engine_root/'openmw.exe'), '--replace', 'config', '--config', str(output),
            '--replace', 'data', '--data', str(args.engine_root/'resources/vfs-mw'),
            str(args.game_data), str(MOD), str(ROOT/'tests/arcane_critical'),
            '--data-local', str(output), '--replace', 'content', '--content',
            'Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm', 'ArcaneMisfires.esp',
            'ArcaneMisfires.omwscripts', 'Probe.omwscripts',
            '--replace', 'fallback-archive', '--fallback-archive',
            'Morrowind.bsa', 'Tribunal.bsa', 'Bloodmoon.bsa', '--user-data', str(output),
            '--resources', str(args.engine_root/'resources'), '--skip-menu', '--new-game=0',
            '--start', start, '--no-grab']
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        result = subprocess.run(command, capture_output=True, text=True, cwd=args.engine_root,
                                startupinfo=startup, timeout=55)
        log = result.stdout+result.stderr
        (output/'result.txt').write_text(log, encoding='utf-8')
        print('\n'.join(line for line in log.splitlines() if 'AMF_DROP_' in line or ' E]' in line))
        if result.returncode or 'AMF_DROP_PASS:' not in log or any(
                phrase in log for phrase in ('AMF_DROP_FAIL:', ' E]', 'Lua error', 'Failed to load')):
            raise SystemExit(f'Engine check failed: {output / "result.txt"}')


if __name__ == '__main__':
    main()
