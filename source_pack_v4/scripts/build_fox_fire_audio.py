"""Deterministic short breath/flame launch: noise rush plus low transient, no tonal beep."""
from pathlib import Path
import wave
import numpy as np
rate=44100
t=np.arange(int(rate*.21))/rate
rng=np.random.default_rng(259)
noise=rng.normal(size=len(t))
body=np.convolve(noise,np.ones(13)/13,mode='same')
air=noise-np.convolve(noise,np.ones(5)/5,mode='same')
envelope=(1-np.exp(-t/0.004))*np.exp(-t/0.048)
thump=np.sin(2*np.pi*(115*t-110*t*t))*np.exp(-t/0.033)
signal=(body*1.8+air*.18)*envelope+thump*.24
signal*=np.clip((.21-t)/.025,0,1)
signal*=.84/max(abs(signal))
out=Path(__file__).resolve().parents[1]/'experiments/terrace/assets/audio/fox_fire_launch.wav'
with wave.open(str(out),'wb') as f:
    f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
    f.writeframes((signal*32767).astype('<i2').tobytes())
print(out.name, '0.21s mono; peak',float(max(abs(signal))))
