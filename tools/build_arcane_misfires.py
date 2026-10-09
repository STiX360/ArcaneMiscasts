"""Build original backfire spell records and a reproducible standalone archive."""
from pathlib import Path
import json
import re
import struct
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'Arcane Misfires'
VERSION = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
if not re.fullmatch(r'\d+\.\d+\.\d+', VERSION):
    raise ValueError('VERSION must contain a numeric X.Y.Z version')
PACKAGE_FILES = (
    'ArcaneMisfires.esp', 'ArcaneMisfires.omwscripts', 'README.md',
    'scripts/arcane_misfires/player.lua',
    'scripts/arcane_misfires/policy.lua', 'l10n/ArcaneMisfires/en.yaml',
)


def sub(tag, data):
    return tag.encode('ascii') + struct.pack('<I', len(data)) + data


def text(tag, value):
    return sub(tag, value.encode('ascii') + b'\0')


def record(tag, *fields):
    body = b''.join(fields)
    return tag.encode('ascii') + struct.pack('<III', len(body), 0, 0) + body


def build():
    entries = json.loads((MOD / 'outcomes.json').read_text())
    spells = []
    for entry in entries:
        for index in range(3):
            magnitude = entry['magnitude'][index]
            spells.append(record('SPEL', text('NAME', f"amf_{entry['key']}_{index+1}"),
                text('FNAM', entry['name']), sub('SPDT', struct.pack('<iii', 0, 0, 0)),
                sub('ENAM', struct.pack('<hbbiiiii', entry['effect'], -1, -1, 0, 0,
                    entry['duration'][index], magnitude, magnitude))))
    header = record('TES3', sub('HEDR', struct.pack('<fi32s256si', 1.3, 0,
        b'Arcane Misfires', b'Original temporary backfire effects for OpenMW.', len(spells))),
        text('MAST', 'Morrowind.esm'), sub('DATA', struct.pack('<Q', 0)))
    (MOD / 'ArcaneMisfires.esp').write_bytes(header + b''.join(spells))
    output = ROOT / f'dist/Arcane-Misfires-{VERSION}.zip'
    output.parent.mkdir(exist_ok=True)
    with ZipFile(output, 'w', compression=ZIP_DEFLATED) as archive:
        for name in sorted(PACKAGE_FILES):
            path = MOD / name
            info = ZipInfo(name, (2026, 10, 8, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
    print(output)


if __name__ == '__main__':
    build()
