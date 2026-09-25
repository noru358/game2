from pathlib import Path
import json, hashlib, collections, re, wave, csv
from PIL import Image,ImageDraw,ImageFont
R=Path('source_pack_v4'); O=Path('docs/audit_v4'); O.mkdir(parents=True,exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
manifest=json.loads((R/'PACKAGE_MANIFEST.json').read_text('utf-8'))
bad=[]; rows=[]; hashes=collections.defaultdict(list)
for i,x in enumerate(manifest['files'],1):
 p=R/x['path']; b=p.read_bytes(); h=hashlib.sha256(b).hexdigest(); hashes[h].append(x['path'])
 if h!=x['sha256'] or len(b)!=x['bytes']:bad.append(x['path'])
 rows.append({'id':i,'path':x['path'],'bytes':len(b),'sha256':h,'extension':p.suffix})
with (O/'ALL_FILES.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
 b=(R/'PACKAGE_MANIFEST.json').read_bytes()
 w.writerow({'id':len(rows)+1,'path':'PACKAGE_MANIFEST.json','bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'extension':'.json'})
imgs=[]
for p in sorted(R.rglob('*.png')):
 im=Image.open(p); im.load(); a=im.convert('RGBA').getchannel('A'); hist=a.histogram();
 imgs.append({'id':len(imgs)+1,'path':p.relative_to(R).as_posix(),'size':im.size,'mode':im.mode,'alpha_bbox':a.getbbox(),'opaque_bbox':a.point(lambda x:255 if x>=128 else 0).getbbox(),'alpha_zero':hist[0],'alpha_full':hist[255],'alpha_partial':sum(hist[1:255])})
def sheet(items,name,cols=3,cell=(500,400)):
 out=Image.new('RGB',(cols*cell[0],((len(items)+cols-1)//cols)*cell[1]),'#d2d5d9');d=ImageDraw.Draw(out)
 for j,(label,im) in enumerate(items):
  x=j%cols*cell[0];y=j//cols*cell[1]; im=im.convert('RGBA'); im.thumbnail((cell[0]-20,cell[1]-50))
  out.paste(im,(x+(cell[0]-im.width)//2,y+35+(cell[1]-45-im.height)//2),im)
  d.text((x+8,y+8),label,font=font,fill='black')
 out.save(O/(name+'.jpg'),quality=93)
for g,sel in [('refs',[x for x in imgs if x['path'].startswith('docs/')]),('runtime',[x for x in imgs if not x['path'].startswith('docs/')])]:
 for start in range(0,len(sel),6):sheet([(f"{x['id']:02} {Path(x['path']).stem[-26:]}",Image.open(R/x['path'])) for x in sel[start:start+6]],f'{g}_{start//6+1}',2,(700,500))
refs=json.loads((R/'docs/design_refs/ASSET_MANIFEST.json').read_text('utf-8'))['files']
individual=sorted([x for x in refs if x['gallery_individual_order']],key=lambda x:x['gallery_individual_order'])
sheet([(f"PNG {x['gallery_individual_order']}",Image.open(R/'docs/design_refs'/x['file'])) for x in individual],'latest8',4,(360,440))
audio=[]
for p in R.rglob('*.wav'):
 with wave.open(str(p)) as w: audio.append({'path':p.relative_to(R).as_posix(),'seconds':w.getnframes()/w.getframerate(),'channels':w.getnchannels(),'rate':w.getframerate(),'samplewidth':w.getsampwidth()})
result={'file_count':len(rows)+1,'manifest_verified':len(rows),'bad_hashes':bad,'duplicates':[v for v in hashes.values() if len(v)>1],'images':imgs,'audio':audio}
(O/'INVENTORY.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
