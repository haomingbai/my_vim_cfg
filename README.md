# Vim 迁移版配置（从 Neovim/Lua 复刻）

本目录用于在不污染其它机器配置的前提下，把当前 Neovim 工作流迁移到 Vim（Vimscript）。

## 目录结构

- `vimrc`：入口配置文件（建议部署为 `~/.vimrc`）
- `vim/`：Vim runtime 目录（会被 `vimrc` 自动加入 `runtimepath`）
  - `vim/plugin/`：自动加载的功能脚本
    - `template.vim`：新文件模板自动插入（读取 `templates/<ext>.tpl`）
    - `run_code.vim`：`<F5>` 运行当前文件（python/c/cpp）
    - `statusline.vim`：lightline 状态栏配置
  - `vim/after/ftplugin/markdown.vim`：markdown 缩进设置
- `templates/`：新文件模板（从原 Neovim `templates/` 原样复制）
- `coc-settings.json`：Coc 配置（通过 `g:coc_config_home` 指向本目录）
- `plugged/`：vim-plug 下载的插件目录（部署后自动生成，建议加入 gitignore）

## 前置依赖

- Vim：建议 Vim 8.2+（最好 9.x）并带 `+terminal +job +channel`
- Git：用于拉取插件
- Node.js：用于 `coc.nvim`

## 部署（推荐：软链接到家目录）

在仓库根目录（也就是本 README 所在目录）执行：

1. 备份旧配置（如存在）
   - `mv ~/.vimrc ~/.vimrc.bak.$(date +%F)`
   - `mv ~/.vim ~/.vim.bak.$(date +%F)`（可选）

2. 链接 `vimrc` 到家目录
   - `ln -sfn "$PWD/vimrc" ~/.vimrc`

3. 链接 runtime 目录到家目录（可选，但更符合 Vim 默认行为）
   - `ln -sfn "$PWD/vim" ~/.vim`

> 说明：`vimrc` 已经把本目录下的 `vim/` 自动加入 `runtimepath`，所以第 3 步不是必须。

## 安装 vim-plug

本仓库不包含 `plug.vim`（避免直接提交第三方文件）。请安装到你的 Vim autoload 目录：

- `curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`

## 安装插件

打开 Vim 后执行：

- `:PlugInstall`

## 安装 Coc 扩展（LSP/补全）

本仓库的 `vimrc` 已通过 `g:coc_global_extensions` 配置 **启动时自动安装/补齐 Coc 扩展**（近似 Neovim 里 Mason 的 `ensure_installed`，但注意它只负责“扩展”，不负责下载语言服务器二进制）。

如需手动触发（或首次联网失败后重试）：

- `:CocInstall -sync coc-clangd coc-pyright coc-lua coc-rust-analyzer coc-texlab`

### 重要差异：Coc 不能像 Mason 一样统一自动部署 Language Server

- Mason：可以下载/管理很多语言服务器（clangd/texlab/marksman 等）
- Coc：核心是 LSP 客户端 + 扩展管理器；**语言服务器本体通常需要你在系统侧安装，并确保在 `$PATH` 里**。

建议按你的 `ensure_installed` 列表做如下替代：

- `clangd`：用系统包管理器安装（确保 `clangd --version` 可用）
- `pyright`：可选安装 Node 版（确保 `pyright --version` 可用；部分情况下 Coc 扩展也可能自带/自动拉取依赖）
- `lua_ls`（lua-language-server）：用系统包管理器或官方 release 安装（确保 `lua-language-server`/`lua-language-server --version` 可用，具体命令以发行版为准）
- `marksman`：用系统包管理器或官方 release 安装（确保 `marksman --version` 可用）
- `texlab`：用系统包管理器/官方 release/`cargo install texlab` 安装（确保 `texlab --version` 可用）
- `asm_lsp`、`glsl_analyzer`：同理，需自行安装对应可执行文件并放入 `$PATH`（不同项目启动参数可能不同，建议以各自文档为准）

安装完成后可用以下方式自检：

- Vim 内：`:CocInfo`
- 系统侧：`command -v clangd rust-analyzer texlab marksman pyright`

## 快捷键对齐说明

- `<F5>`：运行当前文件（python/c/cpp）
- `<F12>`：跳转到定义（Coc）
- `<F24>`：查找引用（一般等价于 Shift+F12）
- `Ctrl + 鼠标左键`：跳转到定义（Coc，终端需要能上报该鼠标事件）
- `<Leader>h`：hover 文档
- `<Leader>s`：signature help
- `<C-I>`：格式化（注意：Vim 中 `<C-I>` 与 `<Tab>` 等价，可能与 jump list 行为冲突）

### 补全（尽量接近 VS Code）

本仓库默认启用 Coc 自动补全，并尽量做到“弹出列表但不强制预选/插入，显式选择后再确认”：

- `Tab` / `Shift-Tab` / `↑` / `↓`：移动补全候选选择
- `Enter`：确认当前选中的补全项；如果未选中候选则正常换行
- `Esc`：关闭补全列表

> 补全行为主要由 `coc-settings.json` 的 `suggest.noselect` 与 `vimrc` 的 `completeopt` 共同决定。

### 复制到系统剪贴板

- `Ctrl + Shift + C`：复制到系统剪贴板（使用 `+` 寄存器）

> 需要 Vim 带 `+clipboard`，且终端没有拦截该快捷键（不少终端默认将 `Ctrl+Shift+C` 作为“复制”并不传给 Vim）。

## 模板系统

新建带后缀文件（例如 `foo.py`、`bar.cpp`）时，会尝试读取：

- `templates/<ext>.tpl`

并替换以下变量：

- `${FILE}`：文件名
- `${DATE}`：YYYY-MM-DD
- `${YEAR}`：YYYY

## 常见问题

- 插件被下载安装到 `~/plugged`（不想在家目录出现非隐藏目录）：通常是因为 `vimrc` 通过软链接部署为 `~/.vimrc` 时，配置里用到的“仓库根目录”解析成了家目录。更新本仓库的 `vimrc` 后，重新打开 Vim 执行 `:PlugInstall`，插件会下载安装到本仓库目录下的 `plugged/`（位于 `~/.config/...`，不会在 `~` 根目录冒出来）。你也可以手动清理旧目录：`rm -rf ~/plugged`。

- `:echo g:coc_config_home` 输出家目录：同样是软链接导致路径解析取到了 `~/.vimrc` 的父目录。更新本仓库的 `vimrc` 后，重启 Vim 或执行 `:CocRestart` 即可；随后 `g:coc_config_home` 应指向本仓库根目录（与 `coc-settings.json` 同级）。

- `:PlugInstall` 报错：先确认 `~/.vim/autoload/plug.vim` 已正确安装。
- Coc 不工作：确认 Node.js 可用；再检查 `:CocInfo`。
- LSP 找不到：需要系统安装对应语言服务器（例如 `clangd`）。

- Coc 扩展下载失败（GitHub/代理相关）：可在 `coc-settings.json` 设置 `http.proxy`；如果代理端口类型为 SOCKS/HTTP 不匹配，会出现连接失败或超时。
