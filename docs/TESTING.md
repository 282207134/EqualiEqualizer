# 测试与验收记录

验收日期：2026-10-24（Asia/Tokyo）。

## 环境

| 项目 | 环境 |
| --- | --- |
| Flutter / Dart | 3.47.7 / 3.13.5 |
| 主机 | Windows |
| Android 设备 | Android 15 / API 35 / x86_64 模拟器 |
| 屏幕 | 750 × 1624 像素，375 × 812 逻辑像素 |
| 小屏回归 | 320 × 640 逻辑像素，Widget 测试 |
| iOS | 未在 Windows 上构建或运行，需 macOS/Xcode 验收 |

## 自动化检查

`flutter analyze`：通过，无错误或警告。

`flutter test`：9 项通过，覆盖：

1. 歌单新建、重命名、去重、未知歌曲过滤、拖动最终索引及重新加载。
2. 按标题或作者搜索，忽略大小写与首尾空格。
3. 删除上传时清理歌单、收藏、历史与播放队列。
4. 音效参数范围限制和持久化恢复。
5. 手动上一首/下一首、随机播放及进度范围。
6. 小屏首页和全部声音面板无布局溢出。
7. Wi-Fi HTTP 上传、错误地址和不支持的文件类型拒绝，以及服务关闭。
8. 搜索输入替换后正确呈现无结果状态。
9. 验证码阶段保留已提交的找回密码邮箱。

Android 集成测试覆盖实际用户流程并生成 34 张截图：

- 首页、连接来源、Wi-Fi 服务启动/关闭和传输网页访问。
- 本地音频复制、导入列表、空状态。
- 新建歌单、勾选添加、重复添加去重、重命名、实际拖动排序。
- 专辑与热门歌曲列表、歌曲菜单、添加至歌单。
- 原生音频加载；实际报告时长为 32 秒；播放、暂停、上一首和下一首。
- 音量、预设、自定义频段、虚拟器和空间拓宽面板。
- 搜索历史、匹配结果和无结果状态。
- 资料编辑、登录校验、注册页面、忘记密码、演示验证码及重置完成。
- 新建资料保存、重新创建 Controller 后恢复歌单、音效参数和资料。

系统音效能力与流程记录见 [test-results.json](test-results.json)。模拟器返回 Equalizer、BassBoost、Virtualizer 可用；这验证系统接口能力，未进行声学测量或真实耳机听感标定。

## 构建与安装结果

| 检查 | 结果 |
| --- | --- |
| Android Release APK | 构建通过，约 64.3 MB，包含通用架构；安装包为 `dist/Equali-1.0.0.apk`。 |
| 模拟器安装启动 | 安装、清空测试数据后启动通过，应用进程正常，无检测到的崩溃。 |
| Web | `flutter build web --output=build/web` 通过；本次仅验证构建，未执行浏览器交互回归。 |
| 文档 | 全部本地 Markdown 链接、34 张 PNG 尺寸和差异状态已校验。 |

安装启动结果见 [release-smoke.json](release-smoke.json)，额外保留一张带系统栏的 [Release 首页截图](release-home.png)。

## 重现命令

```sh
flutter pub get
flutter analyze
flutter test
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/app_test.dart -d emulator-5554
python tools/build_gallery.py
flutter build apk --release
flutter build web
```

集成测试面向专用测试模拟器，会写入示例歌单和资料。请不要在存有重要个人库的设备上运行。

## 截图验收

截图由集成测试从 Flutter 的真实 Android 渲染面获取，保存在 `docs/screenshots/`，不包含系统状态栏图标。已逐组检查首页、专辑、歌单、播放、音效、账号及全部弹层；没有黄色溢出条或调试横幅。

截图工具会隐藏输入键盘，保留表单及错误提示；完整流程和所有弹层见 [SCREENSHOTS.md](SCREENSHOTS.md)。`tools/build_gallery.py` 会校验全部 34 个文件存在，并生成 Markdown 缩略图目录和本地 HTML 大图画廊。

## 已确认的功能边界

- 登录与找回密码是本地演示；不发送邮件、不存储密码、不创建云端账号。
- 没有第三方身份提供方或 Dropbox API 凭据；Dropbox 通过系统文件提供器选择。
- 均衡器仅对本应用音频生效，依赖 Android 设备实现；Web/iOS 尚无自定义 DSP。
- 视频入口播放系统可解码的音轨，不执行转码和音频导出。
- 示例歌曲映射到原创合成音频；波形为与进度同步的视觉示意。
- 背景媒体通知、锁屏控制、后台持续传歌和耳机实机听感测试不在本次验收范围内。
- Android Release 安装包使用开发签名，仅用于本地安装评审。

