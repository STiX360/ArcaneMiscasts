"""Run genuine failed/successful player casts in an isolated OpenMW game."""
from pathlib import Path
import argparse
import shutil
import struct
import subprocess
from build_arcane_misfires import ROOT, MOD, record, sub, text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine-root', required=True, type=Path)
    parser.add_argument('--game-data', required=True, type=Path)
    args = parser.parse_args()
    output = ROOT / 'reports/arcane-engine-check'
    output.mkdir(parents=True, exist_ok=True)
    fixture = ROOT / 'tests/arcane_engine'
    spells = []
    for kind, cost, flags in [('fail',200,0), ('success',0,4), ('fire',200,0), ('silence',200,0)]:
        spells.append(record('SPEL', text('NAME','amf_test_'+kind), text('FNAM','Test '+kind),
            sub('SPDT',struct.pack('<iii',0,cost,flags)),
            sub('ENAM',struct.pack('<hbbiiiii',{'fire':14,'silence':102}.get(kind,8),-1,-1,0,0,1,1,1))))
    header = record('TES3', sub('HEDR',struct.pack('<fi32s256si',1.3,0,b'Test',b'Isolated casts',4)),
        text('MAST','Morrowind.esm'),sub('DATA',struct.pack('<Q',0)))
    (output/'Test.esp').write_bytes(header+b''.join(spells))
    shutil.copyfile(fixture/'settings.cfg',output/'settings.cfg')
    command = [str(args.engine_root/'openmw.exe'),'--replace','config','--config',str(output),
        '--replace','data','--data',str(args.engine_root/'resources/vfs-mw'),
        str(args.game_data),str(MOD),str(fixture),str(output),'--data-local',str(output),
        '--replace','content','--content','Morrowind.esm','Tribunal.esm','Bloodmoon.esm',
        'ArcaneMisfires.esp','Test.esp','ArcaneMisfires.omwscripts','Smoke.omwscripts',
        '--replace','fallback-archive','--fallback-archive','Morrowind.bsa','Tribunal.bsa','Bloodmoon.bsa',
        '--user-data',str(output),'--resources',str(args.engine_root/'resources'),
        '--skip-menu','--new-game=0','--start',"Seyda Neen, Arrille's Tradehouse",'--no-grab']
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    result = subprocess.run(command,capture_output=True,text=True,cwd=args.engine_root,
        startupinfo=startup,timeout=60)
    log = result.stdout+result.stderr
    print('Engine exit code: '+str(result.returncode))
    (output/'result.txt').write_text(log)
    print('\n'.join(line for line in log.splitlines() if 'AMF_SMOKE' in line or ' E]' in line))
    if result.returncode or 'AMF_SMOKE_PASS' not in log or 'AMF_SMOKE_FAIL:' in log:
        raise SystemExit('Engine test failed: '+str(output/'result.txt'))
    if any(phrase in log for phrase in (' E]', 'Lua error','Failed to load','No data loaded')):
        raise SystemExit('Engine reported errors: '+str(output/'result.txt'))


if __name__ == '__main__':
    main()
