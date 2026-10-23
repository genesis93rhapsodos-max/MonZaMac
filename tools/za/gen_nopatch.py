"""Run LASRecomp's gen.py with the Link's Awakening-specific patch table emptied."""
import runpy, sys
sys.path.insert(0, sys.argv.pop(1))  # LASRecomp/tools
import patches
patches.PATCHES.clear()
sys.argv[0] = 'gen.py'
runpy.run_path(sys.path[0] + '/gen.py', run_name='__main__')
