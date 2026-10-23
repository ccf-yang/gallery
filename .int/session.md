# Session memory — pigallery2

- Workspace: /data/dpsk/1017/pigallery2
- Reply language: 简体中文
- Created: 2026-10-23

## Goal

<!-- What this project/session is trying to achieve. Fill in when known. -->

- 阅读并梳理 PiGallery2 项目（自托管、目录优先的照片画廊网站）的功能与技术架构。

## Decisions

<!-- Durable choices: stack, paths, conventions, constraints. -->

- 项目源码位于 /data/dpsk/1017/pigallery2（上游 bpatrik/pigallery2，版本 3.6.0-edge）。
- 技术栈：TypeScript + Angular 19（前端）+ Express 4 / TypeORM 0.3（后端）+ SQLite + sharp/ffmpeg。
- 目标平台 Armbian（ARM64），只保留简单、快速、自托管画廊所需功能：照片 + 视频、目录浏览、相册、搜索、用户/权限、计划任务。
- 视频使用系统 PATH 中的 ffmpeg/ffprobe（已移除 ffmpeg-static/ffprobe-static），不在 ARM 上做大规模离线转码，保留按需转码与直放。
- 数据库只是缓存：改实体/表结构后可删 data/db 重新索引。
- 前端语言只构建 en + zh（angular.json 已只保留 zh locale，对应 messages.cn.xlf）。
- 每个功能移除独立提交，提交信息附 Co-Authored-By: Claude Code <noreply@anthropic.com>（2026-10-23 19:10 起不再使用 git，此约定失效）。
- 2026-10-23 19:10 按用户要求删除 .git/.github/.gitignore，项目不再由 git 管理，无法回滚历史改动。
- 2026-10-23 19:10 删除诊断测试图 test.arw 与 test.dng（省 27.5MB），保留其他小格式测试图；诊断会自动跳过缺失格式。

## Progress

- 2026-10-23 16:57 session initialized by /int
- 2026-10-23 16:57 完成首轮项目结构、文档与功能梳理
- 2026-10-23 17:05 输出精简版（Armbian）规划：.int/minimal-armbian-plan.md
- 2026-10-23 17:20 决策：不重写，裁剪现有项目；保留视频；删除分享/博客/上传；不同步上游
- 2026-10-23 17:40 删除上传功能（后端 router/middleware/manager + 前端 uploader UI + multer 依赖），提交 c156e05d
- 2026-10-23 17:55 删除地图/GPX/GPS 位置元数据及 distance/position 搜索，移除 leaflet、node-geocoder、xml2js 运行依赖，提交 2bcc5116
- 2026-10-23 18:05 删除人脸功能（persons、人像页、人脸搜索/排序、Person 实体），提交 83cd04ba
- 2026-10-23 18:12 删除随机图片链接生成器与相框生成器，提交 3c156c8e
- 2026-10-23 18:20 删除 Live Photo 支持，提交 a16c4676
- 2026-10-23 18:30 删除扩展系统（ExtensionManager/装饰器、扩展安装 UI、媒体按钮、扩展配置），重写 Config.ts 直接加载 PrivateConfigClass，提交 f75ce88f
- 2026-10-23 18:31 改用系统 ffmpeg，移除 adm-zip/ffmpeg-static/ffprobe-static 依赖，精简 README 与 docker 构建脚本，提交 57579624
- 2026-10-23 18:33 生产构建修复：angular.json 仅保留 en/zh，xml2js 移到 devDependencies；`npm run build` 通过（dist/en, dist/zh），提交 275e9be3
- 2026-10-23 18:34 冒烟测试受限：当前环境 Node v25.6.0、better-sqlite3 无原生 binding 且无 node-gyp 头文件，后端无法启动；项目要求 Node 22（需在目标机用 Node 22 验证）
- 2026-10-23 19:10 删除 .git（151MB）与 RAW 测试图；语言/构建验证此前已通过
- 2026-10-23 19:20 清理全部构建产物/缓存/文档，移动依赖到 /tmp/pg2-deps/node_modules；项目仅 3.3MB
- 2026-10-23 19:20 删除 diagnostics/image_formats 全部测试图，新增 TODO.md 与 restore-upstream-assets.sh（可从上游按需恢复）；gulpfile 对缺失诊断目录做了兼容
- 2026-10-23 19:30 进一步最小化：删除 en/cn 翻译(800KB)、docker 配置、package-lock(470KB)、test 配置与 angular test target；仓库 2.0MB
- 2026-10-23 19:30 重写 restore-upstream-assets.sh：默认恢复 en/cn 翻译 + docker（排除 md），--diagnostics 恢复测试图，--lockfile 生成锁文件；明确不恢复 test/docs/benchmark/扩展/其他语言
