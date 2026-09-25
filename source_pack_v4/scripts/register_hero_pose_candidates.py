"""Candidate registration: contour isolation, alpha cleanup, unchanged foreground RGB."""
from pathlib import Path
import json
import copy
import numpy as np
from PIL import Image
from hero_alpha_components import characters
ROOT=Path(__file__).resolve().parents[1]/'experiments/terrace/art_review/hero_pose_v2'
directions={'locomotion':0,'front_right':1,'front':2,'back':6,'back_right':7}
available=[n for n in directions if (ROOT/f'{n}_source.png').exists()]
attacks={'attack':1,'attack_right':0,'attack_front':2,'attack_front_left':3,'attack_left':4,'attack_back_left':5,'attack_back':6,'attack_back_right':7}
available_attacks=[n for n in attacks if n not in ['attack_front_left','attack_back_left'] and (ROOT/f'{n}_source.png').exists()]
manifest={'status':'CANDIDATE_NOT_ACCEPTED','final_directions':8,'coverage':[directions[n] for n in available],'attack_coverage':sorted(attacks[n] for n in available_attacks),'frames':[]}
CELL,PAD=576,8
for name,cols,rows in [(n,4,2) for n in available]+[(n,3,3) for n in available_attacks]:
    is_attack=name in attacks
    original=np.array(Image.open(ROOT/f'{name}_source.png').convert('RGBA'))
    height,width=original.shape[:2]
    objects=characters(original[:,:,3]>=180,cols,rows)
    atlas=np.zeros((rows*CELL,cols*CELL,4),dtype=np.uint8)
    local_frames=[]
    for i,(box,mask) in enumerate(objects):
        row,col=divmod(i,cols)
        x0,y0,x1,y1=box
        crop=original[y0:y1,x0:x1].copy()
        own=mask[y0:y1,x0:x1]
        crop[:,:,3]=np.where(own,255,0)
        h,w=crop.shape[:2]
        if max(h,w)+2*PAD>CELL:raise ValueError(f'{name} silhouette exceeds cell: {box}')
        assert np.array_equal(crop[own,:3],original[y0:y1,x0:x1][own,:3])
        atlas[row*CELL+PAD:row*CELL+PAD+h,col*CELL+PAD:col*CELL+PAD+w]=crop
        head_x=np.where(own[int(h*.18):int(h*.43)])[1]
        root_x=float(np.median(head_x))+PAD
        if not is_attack and row==1:
            lateral={0:1,1:.7,2:0,3:-.7,4:-1,5:-.7,6:0,7:.7}[directions[name]]
            root_x-=h*.10*lateral
        f={'sheet':name+'.png','state':('walk' if row==0 else 'run') if not is_attack else 'attack','step':row+1 if is_attack else 0,'frame':col,'direction':attacks[name] if is_attack else directions[name],'region':[col*CELL,row*CELL,CELL,CELL],'top':PAD,'foot':PAD+h-1,'visible_sole_y':PAD+h-1,'source_sole_y':y1-1-row*height/rows,'root_x':root_x,'source_origin':[x0,y0],'source_grid_origin':[col*width/cols,row*height/rows],'padding':PAD,'height_reference':height/rows*.94,'anchor_status':'head_center_candidate_not_final_hip_registration','silhouette_isolated':True}
        if is_attack:
            # Release-cell glove centres, visually annotated on each source sheet.
            anchors={0:[(.755,.565),(.36,.46),(.82,.645)],1:[(.658,.569),(.292,.502),(.775,.603)],2:[(.63,.55),(.37,.50),(.61,.73)],3:[(.25,.55),(.70,.50),(.30,.70)],4:[(.24,.58),(.71,.48),(.55,.56)],5:[(.23,.55),(.77,.39),(.38,.71)],6:[(.68,.62),(.66,.595),(.78,.68)],7:[(.80,.57),(.68,.49),(.75,.66)]}
            u,v=anchors.get(attacks[name],[(.5,.55),(.5,.5),(.5,.7)])[row]
            f['hands']=[[col*width/cols+u*width/cols-x0+PAD,row*height/rows+v*height/rows-y0+PAD]]
            f['hand_status']='GPU_reviewed_release_anchor' if col==1 else 'unused_nonrelease_anchor'
        local_frames.append(f)
    run=[f for f in local_frames if f['state']=='run']
    if run:
        baseline=max(f['source_sole_y'] for f in run)
        for f in run:
            f['gait_role']='support' if f['frame']%2 else 'flight'
            if f['gait_role']=='flight':
                f['foot']+=max(baseline-f['source_sole_y'],f['height_reference']*.055)
    manifest['frames'].extend(local_frames)
    Image.fromarray(atlas).save(ROOT/f'{name}.png')
    print(name, 'isolated',len(objects),'complete silhouettes')
# Focused strips replace either a half-cycle or a coherent four-pose cycle.
# Keep native resolution; scale only at runtime.
pair_specs=json.loads((ROOT/'pose_overrides.json').read_text(encoding='utf-8'))['pairs']
for spec in pair_specs:
    pair_name,direction,state=spec['name'],spec['direction'],spec['state']
    indices=spec.get('indices', [spec.get('start',0),spec.get('start',0)+1])
    count=len(indices)
    assert count in (2,4) and len(set(indices))==count and all(0<=i<4 for i in indices)
    pair_path=ROOT/(pair_name+'_source.png')
    if not pair_path.exists():continue
    original=np.array(Image.open(pair_path).convert('RGBA'))
    objects=characters(original[:,:,3]>=180,count,1)
    max_side=max(max(box[2]-box[0],box[3]-box[1])+2*PAD for box,_ in objects)
    pair_cell=1 << (int(max_side)-1).bit_length()
    atlas=np.zeros((pair_cell,pair_cell*count,4),dtype=np.uint8)
    reference=[next(f for f in manifest['frames'] if f['direction']==direction and f['state']==state and f['frame']==index) for index in indices]
    visible_ratio=sum((f['visible_sole_y']-f['top'])/f['height_reference'] for f in reference)/len(reference)
    reference_height=sum(box[3]-box[1]-1 for box,_ in objects)/len(objects)/visible_ratio
    manifest['frames']=[f for f in manifest['frames'] if not (f['direction']==direction and f['state']==state and f['frame'] in indices)]
    for i,(box,mask) in enumerate(objects):
        x0,y0,x1,y1=box
        crop=original[y0:y1,x0:x1].copy();own=mask[y0:y1,x0:x1]
        crop[:,:,3]=np.where(own,255,0)
        h,w=crop.shape[:2]
        assert max(h,w)+2*PAD<=pair_cell
        assert np.array_equal(crop[own,:3],original[y0:y1,x0:x1][own,:3])
        atlas[PAD:PAD+h,i*pair_cell+PAD:i*pair_cell+PAD+w]=crop
        f=copy.deepcopy(reference[i])
        lateral={0:1,1:.7,2:0,6:0,7:.7}[direction]
        root_x=float(np.median(np.where(own[int(h*.18):int(h*.43)])[1]))+PAD
        if state=='run':root_x-=h*.10*lateral
        f.update(sheet=pair_name+'.png',frame=indices[i],region=[i*pair_cell,0,pair_cell,pair_cell],top=PAD,visible_sole_y=PAD+h-1,foot=PAD+h-1+(reference_height*.055 if state=='run' and indices[i]%2==0 else 0),height_reference=reference_height,root_x=root_x,source_origin=[x0,y0],source_grid_origin=[i*original.shape[1]/count,0],source_sole_y=y1-1,direction_source='focused pose-strip redraw')
        manifest['frames'].append(f)
    Image.fromarray(atlas).save(ROOT/(pair_name+'.png'))
for source in list(manifest['frames']):
    if source['state'] in ['walk','run'] and source['direction'] in [0,1,7]:
        reflected=copy.deepcopy(source)
        reflected.update(direction={0:4,1:3,7:5}[source['direction']],mirror_h=True,root_x=source['region'][2]-source['root_x'],direction_source='runtime reflection of matching right-side locomotion')
        manifest['frames'].append(reflected)
    if source['state']=='attack' and source['direction'] in [1,7]:
        reflected=copy.deepcopy(source)
        reflected.update(direction={1:3,7:5}[source['direction']],mirror_h=True,root_x=CELL-source['root_x'],direction_source='runtime reflection of matching right diagonal; wrong-facing generated sheet rejected')
        reflected['hands']=[[CELL-x,y] for x,y in source['hands']]
        manifest['frames'].append(reflected)
manifest['attack_coverage']=sorted(set(f['direction'] for f in manifest['frames'] if f['state']=='attack'))
manifest['coverage']=sorted(set(f['direction'] for f in manifest['frames'] if f['state'] in ['walk','run']))
manifest['unique_pose_count']=len(set((f['sheet'],tuple(f['region'])) for f in manifest['frames']))
manifest['mirrored_pose_count']=sum(bool(f.get('mirror_h')) for f in manifest['frames'])
manifest['known_issues']=['some opposite support-leg identities still ambiguous','head registration provisional; anatomical hip and planted foot need review','left-side locomotion and both left-diagonal attacks use runtime reflections','eight attack directions are candidates, not visual acceptance','release glove anchors GPU reviewed; continuous effect trajectory still needs review','alpha threshold may remove faint edges']
(ROOT/'frames.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Registered {len(manifest["frames"])} candidate frames; RGB unchanged; production acceptance FALSE')
