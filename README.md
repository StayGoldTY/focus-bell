# FocusBell

FocusBell 是一个基于 Flutter 的专注计时器应用，提供随机提示音、微休息和深度休息模式。

## 本地开发

```bash
flutter pub get
flutter test
flutter run
```

构建 Web 版本：

```bash
flutter build web --release --base-href /
```

## EdgeOne Pages 自动部署

仓库已经包含 `.github/workflows/deploy-edgeone.yml`，推送到 `master` 后会自动构建并发布到 EdgeOne Pages。

首次配置步骤：

1. 注册或登录 [EdgeOne Pages](https://pages.edgeone.ai/zh/document/importing-a-git-repository) 中国站账号，并开通 Pages 服务。
2. 在 Pages 控制台进入 `API Token` 标签页，创建一个新的 Token。
   描述建议填写 `focus-bell-github-actions`，有效期建议选择 1 年。
3. 在 GitHub 仓库页面进入 `Settings` > `Secrets and variables` > `Actions`，新增名为 `EDGEONE_API_TOKEN` 的仓库 Secret。
4. 推送代码到 `master` 分支，GitHub Actions 会自动执行测试、构建和部署。

工作流中的部署命令如下：

```bash
npx edgeone pages deploy ./build/web -n focus-bell -t $EDGEONE_API_TOKEN
```

根据 EdgeOne 官方文档，如果 `focus-bell` 项目不存在，CLI 会在首次部署时自动创建它。

参考文档：

- [API Token](https://pages.edgeone.ai/zh/document/api-token)
- [EdgeOne CLI](https://pages.edgeone.ai/zh/document/edgeone-cli)
- [使用 GitHub Actions](https://pages.edgeone.ai/zh/document/use-github-actions)
