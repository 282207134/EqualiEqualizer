"""Package portable source and documentation; omit build caches and local settings."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
output = root / 'dist' / 'Equali-source.zip'
output.parent.mkdir(exist_ok=True)
excluded = {'build', 'build_temp', '.dart_tool', '.idea', '.git', '.gradle', '.kotlin',
            'dist', 'ephemeral', 'Pods', '.symlinks', '__pycache__'}
local = {'android/local.properties', '.flutter-plugins-dependencies',
         'ios/Flutter/Generated.xcconfig', 'ios/Flutter/flutter_export_environment.sh'}
count = 0
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(root.rglob('*')):
        if not path.is_file(): continue
        relative = path.relative_to(root)
        if any(part in excluded for part in relative.parts): continue
        if relative.as_posix() in local or path.suffix in {'.log', '.iml', '.pyc'}: continue
        archive.write(path, Path('EqualiEqualizer') / relative)
        count += 1
print(f'Packaged {count} files: {output.name} ({output.stat().st_size / 1024**2:.1f} MB)')
