"""Build test dependencies and run only this mod's Lua and fixture tests."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from build_arcane_misfires import build

if __name__ == '__main__':
    build()
    suite = unittest.TestSuite()
    for pattern in ('test_arcane_misfires.py', 'test_arcane_manual.py'):
        suite.addTests(unittest.defaultTestLoader.discover(str(ROOT / 'tests'), pattern))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(not result.wasSuccessful())
