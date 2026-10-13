"""Check real teleport miscasts with an optional locally supplied Nifty Spell Pack."""
from pathlib import Path
import argparse
import shutil
import struct
import subprocess
from build_arcane_misfires import ROOT, MOD, build, record, sub, text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine-root', required=True, type=Path)
    parser.add_argument('--game-data', required=True, type=Path)
    parser.add_argument('--nifty-data', type=Path)
    args = parser.parse_args()
    build()
    output = ROOT / 'reports' / ('nifty-installed' if args.nifty_data else 'nifty-absent')
    output.mkdir(parents=True, exist_ok=True)
    spells = []
    for name, effect in [('recall', 61), ('divine', 62), ('almsivi', 63)]:
        spells.append(record('SPEL', text('NAME', 'amf_nifty_'+name), text('FNAM', 'Test '+name),
            sub('SPDT', struct.pack('<iii', 0, 200, 0)),
            sub('ENAM', struct.pack('<hbbiiiii', effect, -1, -1, 0, 0, 1, 1, 1))))
    header = record('TES3', sub('HEDR', struct.pack('<fi32s256si', 1.3, 0,
        b'Test', b'Isolated teleport miscasts', len(spells))),
        text('MAST', 'Morrowind.esm'), sub('DATA', struct.pack('<Q', 0)))
    (output/'Test.esp').write_bytes(header+b''.join(spells))
    shutil.copyfile(ROOT/'tests/arcane_engine/settings.cfg', output/'settings.cfg')
    data = [str(args.engine_root/'resources/vfs-mw'), str(args.game_data), str(MOD),
            str(ROOT/'tests/arcane_nifty'), str(output)]
    content = ['Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm', 'ArcaneMisfires.esp',
               'Test.esp', 'ArcaneMisfires.omwscripts', 'Smoke.omwscripts']
    if args.nifty_data:
        data.append(str(args.nifty_data))
        content.append('NiftySpellPack.omwaddon')
    command = [str(args.engine_root/'openmw.exe'), '--replace', 'config', '--config', str(output),
        '--replace', 'data', '--data', *data, '--data-local', str(output),
        '--replace', 'content', '--content', *content,
        '--replace', 'fallback-archive', '--fallback-archive', 'Morrowind.bsa', 'Tribunal.bsa', 'Bloodmoon.bsa',
        '--user-data', str(output), '--resources', str(args.engine_root/'resources'),
        '--skip-menu', '--new-game=0', '--start', "Seyda Neen, Arrille's Tradehouse", '--no-grab']
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    result = subprocess.run(command, capture_output=True, text=True, cwd=args.engine_root,
                            startupinfo=startup, timeout=60)
    log = result.stdout+result.stderr
    (output/'result.txt').write_text(log)
    print('\n'.join(line for line in log.splitlines() if 'AMF_NIFTY' in line or ' E]' in line))
    if result.returncode or 'AMF_NIFTY_PASS' not in log or any(
            phrase in log for phrase in ('AMF_NIFTY_FAIL:', ' E]', 'Lua error', 'Failed to load', 'No data loaded')):
        raise SystemExit('Engine test failed: '+str(output/'result.txt'))


if __name__ == '__main__':
    main()
