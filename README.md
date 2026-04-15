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
