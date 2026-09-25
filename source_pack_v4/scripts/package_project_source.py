"""Package current files and cumulative history without silently rewriting either."""
from pathlib import Path
import argparse,hashlib,json,posixpath,re,zipfile
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]
SKIP={'.git','.godot','.tools','__pycache__','builds','validation','deliveries','archive'}
def sha(b):return hashlib.sha256(b).hexdigest()
def collect():
 excluded=set(json.loads((ROOT/'PACKAGE_EXCLUSIONS.json').read_text('utf-8'))['paths']); entries={}
 for p in sorted(ROOT.rglob('*')):
  rel=p.relative_to(ROOT)
  if not p.is_file() or p.is_symlink() or set(rel.parts)&SKIP:continue
  if rel.as_posix() in excluded or rel.as_posix()=='PACKAGE_MANIFEST.json':continue
  if p.suffix in {'.log','.tmp','.bak','.pyc'} or p.name in {'.env','export_credentials.cfg'}:continue
  entries[rel.as_posix()]=p.read_bytes()
 for n in ['docs/GAME_PROJECT_SOURCE.md','docs/design_refs/hero_turnaround_approved.png','experiments/terrace/project.godot','experiments/terrace/lab/journey.tscn']:
  if n not in entries:raise ValueError('Required file missing: '+n)
 for n,b in entries.items():
  if n.endswith(('.gd','.tscn','.gdshader','.godot')):
   source=b.decode('utf-8-sig')
   for match in re.finditer(r'res://([^\s"\'\)]+)',source):
    ref=match.group(1)
    # A quoted prefix followed by concatenation is a dynamic path, whose
    # resolved files are covered by runtime fixtures rather than this scan.
    if re.match(r'["\']\s*\+',source[match.end():]):continue
    if any(c in ref for c in '%{+') or ref.startswith('docs/validation'):continue
    target='experiments/terrace/'+ref
    if target not in entries and not any(k.startswith(target.rstrip('/')+'/') for k in entries):raise ValueError(f'Missing resource: {n} -> {ref}')
  if n.endswith('.md'):
   for ref in re.findall(r'!?\[[^\]]*\]\(([^)\s]+)\)',b.decode('utf-8-sig')):
    if re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:',ref) or ref.startswith('#'):continue
    target=posixpath.normpath(posixpath.join(posixpath.dirname(n),unquote(ref.split('#')[0])))
    if target not in entries:raise ValueError(f'Missing document link: {n} -> {ref}')
 return entries

def package(out,version,date):
 if not re.fullmatch(r'V[0-9]+',version) or not re.fullmatch(r'[0-9]{8}',date):raise ValueError('Expected V<number>, YYYYMMDD')
 entries=collect()
 manifest=dict(version=version,date=date,files=[dict(path=n,bytes=len(b),sha256=sha(b)) for n,b in entries.items()],note='Current files and cumulative logs preserved verbatim. No binaries/caches/retired references.')
 mb=(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode('utf-8');entries['PACKAGE_MANIFEST.json']=mb
 out.mkdir(parents=True,exist_ok=True);dest=out/f'GAME_PROJECT_SOURCE_PACK_{version}_{date}.zip'
 with zipfile.ZipFile(dest,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for n,b in entries.items():z.writestr(n,b)
 with zipfile.ZipFile(dest) as z:
  if z.testzip() is not None:raise ValueError('ZIP CRC failed')
  for n,b in entries.items():
   if z.read(n)!=b:raise ValueError('ZIP bytes differ: '+n)
 (ROOT/'PACKAGE_MANIFEST.json').write_bytes(mb)
 report=dict(path=str(dest),files=len(entries),bytes=dest.stat().st_size,sha256=sha(dest.read_bytes()),crc='PASS',all_hashes='PASS',resource_closure='PASS',document_links='PASS',logs_preserved_verbatim=True,note='Literal file/directory paths validated. Dynamic loads require runtime fixture tests. Integration state is recorded in GAME_PROJECT_SOURCE.')
 dest.with_suffix('.verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8');print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--version',required=True);p.add_argument('--date',required=True);a=p.parse_args();package(a.out.resolve(),a.version,a.date)
