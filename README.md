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

## Vercel 免费域名部署

仓库已经包含 `.github/workflows/deploy-vercel.yml`，可以发布到免费的 `*.vercel.app` 域名。

### 本地一键部署

1. 注册或登录 [Vercel](https://vercel.com/signup)。
2. 首次登录 CLI：

```bash
vercel login
```

3. 首次将当前仓库绑定到一个 Vercel 项目：

```bash
vercel link --yes
```

4. 本地直接构建并发布到生产环境：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-vercel.ps1
```

如果只想先发一个预览地址，可以改用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-vercel.ps1 -Preview
```

### GitHub Actions 自动部署

工作流会先执行 `flutter test`，然后用 `flutter build web --release --base-href /` 构建，再把生成的静态文件打包成 Vercel Build Output 并发布。

首次配置需要 3 个 GitHub Secrets：

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

推荐准备步骤：

1. 在浏览器登录 Vercel，进入 [Account Tokens](https://vercel.com/account/tokens) 创建一个 Token。
2. 在仓库根目录运行一次：

```bash
vercel link --yes
```

3. 打开本地生成的 `.vercel/project.json`，取出 `orgId` 和 `projectId`。
4. 在 GitHub 仓库 `Settings` > `Secrets and variables` > `Actions` 中新增上面 3 个 Secrets。
5. 之后每次推送到 `master`，GitHub Actions 就会自动发布到你的 `vercel.app` 域名。

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
