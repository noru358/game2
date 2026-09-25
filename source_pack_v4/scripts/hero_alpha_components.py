"""Run-length connected components for silhouette masks; no external CV runtime."""
import numpy as np

def components(mask):
    parents=[]
    runs=[]
    previous=[]
    def root(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]]
            i=parents[i]
        return i
    for y,line in enumerate(mask):
        edges=np.flatnonzero(np.diff(np.r_[False,line,False].astype(np.int8)))
        current=[]
        cursor=0
        for x0,x1 in zip(edges[::2],edges[1::2]):
            n=len(parents);parents.append(n)
            while cursor<len(previous) and previous[cursor][1]<x0:cursor+=1
            j=cursor
            while j<len(previous) and previous[j][0]<=x1:
                old=previous[j][2]
                a,b=root(n),root(old)
                if a!=b:parents[a]=b
                j+=1
            current.append((int(x0),int(x1),n))
            runs.append((y,int(x0),int(x1),n))
        previous=current
    labels=np.zeros(mask.shape,dtype=np.int32)
    groups={}
    for y,x0,x1,n in runs:
        r=root(n)+1
        labels[y,x0:x1]=r
        g=groups.setdefault(r,{'id':r,'area':0,'box':[x0,y,x1,y+1]})
        g['area']+=x1-x0
        b=g['box'];b[0]=min(b[0],x0);b[1]=min(b[1],y);b[2]=max(b[2],x1);b[3]=y+1
    return labels,groups

def characters(mask,cols,rows):
    labels,groups=components(mask)
    major=sorted(groups.values(),key=lambda g:g['area'],reverse=True)[:cols*rows]
    major.sort(key=lambda g:(g['box'][1]+g['box'][3])/2)
    ordered=[]
    for row in range(rows):
        ordered.extend(sorted(major[row*cols:(row+1)*cols],key=lambda g:(g['box'][0]+g['box'][2])/2))
    assigned={g['id']:[g['id']] for g in ordered}
    major_ids=set(assigned)
    for g in groups.values():
        if g['id'] in major_ids or g['area']<8:continue
        a=g['box']
        choices=[]
        for m in ordered:
            b=m['box']
            gap=max(0,a[0]-b[2],b[0]-a[2])+max(0,a[1]-b[3],b[1]-a[3])
            center=abs(a[0]+a[2]-b[0]-b[2])+abs(a[1]+a[3]-b[1]-b[3])
            choices.append((gap+center*.02,gap,m['id']))
        _,gap,target=min(choices)
        if gap<=12:assigned[target].append(g['id'])
    result=[]
    for g in ordered:
        ids=assigned[g['id']]
        boxes=[groups[i]['box'] for i in ids]
        box=[min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes)]
        result.append((box,np.isin(labels,ids)))
    return result
