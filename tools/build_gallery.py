from pathlib import Path
from html import escape

root = Path(__file__).resolve().parents[1]
screens = [
 ('01-home','音乐首页'),('02-connect','连接来源'),('03-wifi-transfer','Wi-Fi 传输'),
 ('04-uploads-empty','上传空状态'),('05-uploads','本地上传列表'),('06-playlists','全部歌单'),
 ('07-new-playlist','新建歌单'),('08-add-songs','添加歌曲'),('09-playlist','歌单详情'),
 ('10-playlist-menu','歌单菜单'),('11-edit-playlist','重命名歌单'),('12-song-order','歌曲排序'),
 ('13-album','专辑列表'),('14-song-menu','歌曲菜单'),('15-add-to-playlist','添加至歌单'),
 ('16-today-hits','今日热门'),('17-player','唱片播放器'),('18-volume','音量'),
 ('19-equalizer','均衡器'),('20-virtualizer','低音与虚拟器'),('21-surround','空间拓宽'),
 ('22-search-history','搜索历史'),('23-search-results','搜索结果'),('24-search-empty','无结果'),
 ('25-profile','个人资料'),('26-edit-profile','编辑资料'),('27-sign-in','登录'),
 ('28-sign-in-validation','登录校验'),('29-register','注册'),('30-forgot-password','忘记密码'),
 ('31-verification','验证码'),('32-reset-password','重置密码'),('33-reset-success','重置完成'),
 ('34-create-profile','创建资料')]

missing = [name for name, _ in screens if not (root / 'docs/screenshots' / f'{name}.png').exists()]
if missing:
    raise SystemExit(f'Missing screenshots: {missing}')
lines = ['# 全部界面截图', '', '以下 34 张 PNG 来自 Android 15 模拟器实际运行，分辨率为 750 × 1624。覆盖页面、弹层、空状态和表单校验。', '',
         '[打开可浏览的大图画廊](screenshots/index.html) · [返回项目说明](../README.md)', '', '| 编号 | 页面 | 原图 |', '| --- | --- | --- |']
for i, (name, label) in enumerate(screens, 1):
    lines.append(f'| {i:02} | {label} | [{name}.png](screenshots/{name}.png) |')
lines += ['', '## 页面缩略图', '']
for i in range(0, len(screens), 3):
    group = screens[i:i+3]
    lines += ['| ' + ' | '.join(label for _, label in group) + ' |', '| ' + ' | '.join('---' for _ in group) + ' |',
              '| ' + ' | '.join(f'![{label}](screenshots/{name}.png)' for name, label in group) + ' |', '']
(root / 'docs/SCREENSHOTS.md').write_text('\n'.join(lines), encoding='utf-8')
body = '\n'.join(f'<a href="{name}.png" target="_blank"><img loading="lazy" src="{name}.png" alt="{escape(label)}"><span>{name[:2]} / {escape(label)}</span></a>' for name,label in screens)
html = '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Equali · 界面截图</title><style>body{background:#e9f0f7;color:#303745;font:16px system-ui;margin:0;padding:40px}h1{font-size:40px;color:#5b66f2}p{color:#596882}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:28px;margin-top:40px}a{color:inherit;text-decoration:none}img{width:100%;border-radius:20px;box-shadow:5px 5px 16px #becbdc}span{display:block;margin:12px 0 28px;font-size:14px}</style><h1>Equali</h1><p>34 个实际运行界面 · Android 15 · 点击图片查看原图</p><main>' + body + '</main></html>'
(root / 'docs/screenshots/index.html').write_text(html, encoding='utf-8')
print(f'Gallery verified: {len(screens)} images')
