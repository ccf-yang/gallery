# 待恢复资源与后续事项

本项目按“最小仓库”原则清理：构建产物、缓存、依赖、文档、测试、翻译和大文件都已移出。
以下记录哪些文件是**当前项目仍然需要、但从仓库里删掉了**，以及如何从上游恢复。
功能代码**不在恢复范围内**。

## 上游信息

- 仓库：`https://github.com/bpatrik/PiGallery2.git`
- 当前代码对应的版本：`3.6.0-edge`（见 `package.json`）
- 上游可能继续变化，路径和内容以实际仓库为准；建议用 `--ref` 固定到某个 tag/commit。
- 恢复脚本：`./restore-upstream-assets.sh`

```bash
# 默认：恢复构建必需的 en/cn 翻译 + docker 配置
./restore-upstream-assets.sh

# 额外恢复格式诊断测试图
./restore-upstream-assets.sh --diagnostics

# 生成 package-lock.json（需要 npm 和网络）
./restore-upstream-assets.sh --lockfile

# 固定上游版本
./restore-upstream-assets.sh --ref v3.6.0
```

脚本会把仓库克隆到 `/tmp/pigallery2-upstream`，再用 `cp -n` 复制到本项目；
默认不覆盖现有文件，需要覆盖时加 `--force`。仓库已存在时会 `git fetch` 更新。

## 从仓库删除、需要时可恢复的内容

| 资源 | 上游路径 | 本地落点 | 体积（约） | 说明 |
|---|---|---|---:|---|
| 中英文翻译 | `src/frontend/translate/messages.en.xlf`、`messages.cn.xlf` | 同路径 | 800 KB | **构建必需**，脚本默认恢复 |
| Docker 配置 | `docker/**`（不含 `*.md`） | `docker/` | 40 KB | 部署才需要，脚本默认恢复；脚本会自动保留“使用系统 ffmpeg”的本地修改 |
| 格式诊断测试图 | `src/backend/model/diagnostics/image_formats/` | 同路径 | 29 MB | 可选；缺失时诊断跳过格式检测，不影响运行，需 `--diagnostics` |
| `package-lock.json` | 由 `package.json` 生成 | `./package-lock.json` | 470 KB | 用 `--lockfile` 或 `npm install` 生成 |

## 明确不恢复的内容

- `test/`：测试代码，当前裁剪版不兼容，脚本不会恢复。
- `docs/`、`README.md`：文档，不影响构建和运行。
- `benchmark/`：基准测试。
- `extension/`：示例扩展，扩展系统已删除。
- `messages.de/es/fr/...`：其他语言翻译，当前只构建 en/zh；如确需，恢复后还要在
  `angular.json` 的 `i18n.locales` 中登记。
- 所有已删除功能的源码和配置：分享/博客、上传、人脸、地图/GPX/GPS、扩展、OIDC、
  MySQL/MariaDB、邮件、Live Photo、随机图片链接、相框生成器、demo/示例。
- `ffmpeg-static`、`ffprobe-static`、`adm-zip`、`xml2js` 运行依赖（视频改用系统 ffmpeg）。

如果确实要恢复某个功能，应整体对照上游重新接线（路由、配置、实体、前端），
不能只复制单个文件夹。

## 依赖与构建产物

- `node_modules/` 已移动到 `/tmp/pg2-deps/node_modules`，不在项目目录内。
  - 恢复：`mv /tmp/pg2-deps/node_modules node_modules`
  - 或离线重装：`npm ci --offline`（需要先有 `package-lock.json`）
  - 或在目标机联网安装：`npm install`
- `dist/`、`src/**/*.js`、`.angular/` 都是构建产物，运行 `npm run build` 重新生成。
- `config.json`、`data/`、`db/`、`tmp/` 是运行时生成，首次启动自动创建。
- 数据库只是缓存，删除 `data/db/` 后重新索引即可。

## 恢复后的验证

```bash
./restore-upstream-assets.sh          # 至少恢复翻译
mv /tmp/pg2-deps/node_modules node_modules
npx tsc --noEmit
npm run build
```

恢复诊断测试图后，可在后台保存一次配置，确认日志里各格式检测结果正常。
