# FocusBell

FocusBell 是一个基于 Flutter 的专注计时器应用，提供随机提示音、微休息和深度休息模式。

线上地址：

- [https://staygoldty.github.io/focus-bell/#/timer](https://staygoldty.github.io/focus-bell/#/timer)

## 本地开发

```bash
flutter pub get
flutter test
flutter run
```

## 背景音与提示音

所有声音都是离线合成的，仓库里没有音频资源文件，也不依赖外部 API。

- `lib/core/audio/ambient_recipe.dart`：背景音的声明式「配方」——噪声层（白 / 粉 / 棕 + 滤波 + 慢速 LFO）、持续音层（音垫、双耳节拍）和随机事件层（雨滴、噼啪、远雷、鸟鸣）。
- `lib/core/constants/sound_data.dart`：17 种内置背景音的配方与分类（自然 / 噪音 / 氛围）。
- `web/focus_audio.js`：Web 端实时引擎（Web Audio API），同时负责提示音（分音 + 击打瞬态 + 短混响）。
- `lib/core/audio/ambient_renderer.dart`：原生端离线渲染器，把同一份配方渲染成可无缝循环的立体声 WAV。

两个引擎逐层对应，改配方时两边会同时生效；`test/ambient_renderer_test.dart` 会检查每个声音的电平、响度平衡和循环接缝。

构建 GitHub Pages 版本：

```bash
flutter build web --release --base-href /focus-bell/
```

## GitHub Pages 自动发布

仓库已经包含 `.github/workflows/deploy-github-pages.yml`。

默认流程：

1. 代码推送到 `master`
2. GitHub Actions 自动执行 `flutter test`
3. 自动构建 Web 产物
4. 自动发布到 `gh-pages` 分支
5. GitHub Pages 站点更新到上面的固定地址

当前站点地址以这个链接为准：

- [https://staygoldty.github.io/focus-bell/#/timer](https://staygoldty.github.io/focus-bell/#/timer)
