"""Generate self-targeted manual-test spells and a portable test bundle."""
import struct
from zipfile import ZipFile, ZIP_DEFLATED
from build_arcane_misfires import ROOT, MOD, VERSION, record, sub, text


def build():
    fixture = ROOT / 'tests/arcane_manual'
    entries = [('fire','Fire Recoil',14),('frost','Frost Recoil',16),('shock','Shock Recoil',15),
        ('burden','Feather Backfire',8),('blind','Night Eye Backfire',43),
        ('silence','Conjuration Backfire',102),('magicka','Mysticism Backfire',57),
        ('weakness','Shield Backfire',3),('fatigue','Restoration Backfire',75),
        ('success','Guaranteed Success',8),('power','Power Exclusion',8)]
    spells = []
    for key, name, effect in entries:
        control = key in ('success','power')
        spells.append(record('SPEL',text('NAME','amft_'+key),text('FNAM','AM Test - '+name),
            sub('SPDT',struct.pack('<iii',2 if key=='power' else 0,0 if control else 200,4 if control else 0)),
            sub('ENAM',struct.pack('<hbbiiiii',effect,-1,-1,0,0,1,1,1))))
    header=record('TES3',sub('HEDR',struct.pack('<fi32s256si',1.3,0,b'Arcane Misfires',
        b'Disposable manual test spells; never load in a real save.',len(spells))),
        text('MAST','Morrowind.esm'),sub('DATA',struct.pack('<Q',0)))
    (fixture/'ArcaneMisfiresTest.esp').write_bytes(header+b''.join(spells))
    output=ROOT/f'dist/Arcane-Misfires-Test-{VERSION}.zip'
    with ZipFile(output,'w',compression=ZIP_DEFLATED) as archive:
        for directory in (MOD,fixture):
            for path in sorted(directory.rglob('*')):
                if path.is_file(): archive.write(path,path.relative_to(ROOT).as_posix())
        for name in ('Test-Arcane-Misfires.cmd','TESTING-ARCANE-MISFIRES.md','tools/start-arcane-test.ps1'):
            archive.write(ROOT/name,name)
    print(output)


if __name__=='__main__':
    build()
