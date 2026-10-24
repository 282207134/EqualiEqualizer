"""Regenerate original demo music and application icons. Requires numpy and Pillow."""
from pathlib import Path
import wave
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
rate, seconds = 22050, 32
t = np.arange(rate * seconds) / rate
rng = np.random.default_rng(41)
for index, name in enumerate(('aurora', 'afterglow', 'drift')):
    signal = np.zeros_like(t)
    chords = ((57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62))
    for beat in range(64):
        start = beat * .5
        mask = (t >= start) & (t < start + .48)
        local = t[mask] - start
        chord = chords[(beat // 8 + index) % 4]
        note = chord[beat % 3] + (12 if beat % 4 == 3 else 0)
        frequency = 440 * 2 ** ((note - 69) / 12)
        env = np.minimum(local / .012, 1) * np.exp(-local * (4 + index))
        signal[mask] += (.12 * np.sin(2 * np.pi * frequency * local)
                        + .025 * np.sin(4 * np.pi * frequency * local)) * env
        if beat % 2 == 0:
            kick = np.sin(2*np.pi*(55*local+35*(1-np.exp(-local*22)))) * np.exp(-local*18)
            signal[mask] += kick * .17
        if beat % 4 == 2:
            signal[mask] += rng.normal(0, .035, len(local)) * np.exp(-local*35)
        bass = 440 * 2 ** ((chord[0] - 81) / 12)
        signal[mask] += .09 * np.sin(2*np.pi*bass*local) * np.exp(-local*3)
    fade = np.minimum(t / .3, 1) * np.minimum((seconds - t) / .8, 1)
    left = signal * fade
    right = (.93 * signal + .07 * np.roll(signal, 331)) * fade
    stereo = np.stack((left, right), axis=1)
    with wave.open(str(ROOT / 'assets' / 'audio' / f'{name}.wav'), 'wb') as output:
        output.setnchannels(2); output.setsampwidth(2); output.setframerate(rate)
        output.writeframes((np.clip(stereo, -1, 1) * 32767).astype('<i2').tobytes())

icon = Image.new('RGB', (1024, 1024), '#5B66F2')
draw = ImageDraw.Draw(icon)
for x, y in ((310, 350), (512, 625), (714, 440)):
    draw.rounded_rectangle((x-22, 220, x+22, 804), radius=22, fill='#DCE2FF')
    draw.rounded_rectangle((x-62, y-62, x+62, y+62), radius=32, fill='white')
for folder, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    icon.resize((size,size),Image.Resampling.LANCZOS).save(ROOT / f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png')
for path in (ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset').glob('*.png'):
    with Image.open(path) as original: size=original.size
    icon.resize(size,Image.Resampling.LANCZOS).save(path)
for path in (ROOT / 'web/icons').glob('*.png'):
    with Image.open(path) as original: size=original.size
    icon.resize(size,Image.Resampling.LANCZOS).save(path)
icon.resize((32,32),Image.Resampling.LANCZOS).save(ROOT / 'web/favicon.png')
