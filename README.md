# Webhostmost-ws-nodejs 配置小助手 (app.ps1 Windows版 / app.sh macOS版) 使用指南

## 嗨，朋友们！

欢迎使用这个配置小助手！无论你是 Windows 用户还是 Mac 用户，这个指南都会告诉你如何使用对应的脚本 (`app.ps1` for Windows, `app.sh` for macOS) 来轻松配置和部署 `Webhostmost-ws-nodejs` 项目。这些脚本能帮你省去不少手动操作的麻烦。

## 感谢这些朋友
* **核心功能主要来自 (Core Functionality By)**:
    * [https://github.com/eooce](https://github.com/eooce)
    * [https://github.com/qwer-search](https://github.com/qwer-search)
* **这个配置脚本的作者 (Script Author)**: Joey
    * 博客 (Blog): joeyblog.net
    * 有啥想说的，来TG聊聊 (Feedback TG): [https://t.me/+ft-zI76oovgwNmRh](https://t.me/+ft-zI76oovgwNmRh)


## 这个脚本能帮你做什么？

简单来说，这个配置脚本是你的好帮手：

1.  **轻松配置**: 它会像聊天一样问你几个简单的问题，比如你的域名、想要的 UUID、端口号，还有自定义的订阅路径，以及（如果你需要的话）Nezha 监控的那些设置。
2.  **自动下载**: 它会帮你从 GitHub 上把最新的 `app.js` 和 `package.json` 文件下载到你的电脑上。
3.  **智能修改**: 根据你给的信息，它会自动修改 `app.js` 文件里的默认设置。
4.  **清晰总结**: 最后，它会把所有配置信息，包括 VLESS 订阅链接和文件要上传到哪里，都清楚地告诉你。

## 开始之前，你需要…

**通用条件:**
* 稳定的网络连接，以便下载配置文件。

**Windows 用户:**
* Windows 操作系统。
* 已安装 PowerShell (通常 Windows 自带)。

**macOS 用户:**
* 一台 macOS 系统的电脑。
* Bash (macOS 通常都自带了，在“终端”里就能用)。
* `curl` 命令 (macOS 通常也自带了)。
* `uuidgen` 命令 (macOS 通常也自带了，用于生成 UUID)。

## 怎么用呢？

请根据你的操作系统选择对应的方法：

### Windows 用户 (使用 `app.ps1`)

#### 方法一：手动下载和运行脚本 (如果已有 `app.ps1` 文件)

1.  **拿到脚本**: 如果你已经有 `app.ps1` 这个 PowerShell 脚本文件了，把它存到你电脑上一个方便找的地方。
2.  **运行脚本**:
    * 打开 PowerShell（在开始菜单搜一下 PowerShell 就能找到）。
    * **重点来啦**: 先用 `cd` 命令切换到你希望保存 `app.ps1` 和之后生成的 `app.js`、`package.json` 文件的文件夹。比如，你可以 `cd Desktop` (桌面) 或者 `cd Downloads` (下载)，或者自己新建一个文件夹再进去。
    * 然后运行脚本: `.\app.ps1`
    * 如果 PowerShell 提示说不能运行脚本（执行策略问题），试试运行 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` 或者 `Set-ExecutionPolicy Unrestricted -Scope CurrentUser`。运行这些命令前最好了解一下它们是干嘛的。
3.  **跟着提示走**: 脚本会开始问你问题，你照着回答就行。

#### 方法二：通过 PowerShell 命令行快速运行

1.  **重要：先选个工作文件夹**
    * 打开 PowerShell。
    * 用 `cd` 命令切换到一个你打算放脚本和配置文件的文件夹。**这一步非常关键**，因为 `app.ps1` 脚本和后面生成的 `app.js`、`package.json` 都会保存在你运行命令时所在的这个文件夹里。
    * 举个例子，你可以新建一个叫 `MyNodeProject` 的文件夹然后进去：
        ```powershell
        mkdir MyNodeProject
        cd MyNodeProject
        ```
        或者，直接去你常用的“下载”文件夹：
        ```powershell
        cd Downloads
        ```

2.  **运行这行命令**:
    在你选好的文件夹里，复制粘贴下面这行命令，然后按回车：
    ```powershell
    powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '[https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/main/app.ps1](https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/main/app.ps1)' -OutFile 'app.ps1'; & './app.ps1'"
    ```
    这行命令会帮你做这些事：
    * `powershell -ExecutionPolicy Bypass -Command "..."`: 临时用一个比较宽松的权限来运行 PowerShell 命令。
    * `Invoke-WebRequest -Uri '...' -OutFile 'app.ps1'`: 从指定的网址下载 `app.ps1` 脚本，并把它存到你当前的文件夹里。
    * `& './app.ps1'`: 运行刚下载好的 `app.ps1` 脚本。

3.  **跟着提示走**: `app.ps1` 脚本启动后，就会开始问你问题啦。

### macOS 用户 (使用 `app.sh`)

#### 方法一：手动下载脚本再运行 (如果你已经有 `app.sh` 文件了)

1.  **拿到脚本**: 如果你已经有 `app.sh` 这个 Bash 脚本文件了，把它存到你电脑上一个方便找的地方。
2.  **赋予执行权限**: 打开“终端” (Terminal) 应用。
    * 使用 `cd` 命令切换到你保存 `app.sh` 文件的文件夹。例如，`cd ~/Downloads`。
    * 给脚本加上执行权限：`chmod +x app.sh`
3.  **运行脚本**:
    * **重点来啦**: 确保你当前所在的终端目录就是你希望保存生成的 `app.js` 和 `package.json` 文件的目录。
    * 执行脚本: `./app.sh`
4.  **跟着提示走**: 脚本会开始问你问题，你照着回答就行。

#### 方法二：通过终端命令快速下载并运行 (推荐)

1.  **重要：先选个工作文件夹**
    * 打开“终端” (Terminal)。
    * 用 `cd` 命令切换到一个你打算放脚本和配置文件的文件夹。**这一步非常关键**，因为 `app.sh` 脚本和后面生成的 `app.js`、`package.json` 都会保存在你运行命令时所在的这个文件夹里。
    * 举个例子，你可以新建一个叫 `MyNodeProject` 的文件夹然后进去：
        ```bash
        mkdir ~/MyNodeProject
        cd ~/MyNodeProject
        ```
        或者，直接去你常用的“下载”文件夹：
        ```bash
        cd ~/Downloads
        ```

2.  **运行这行命令**:
    在你选好的文件夹里，复制粘贴下面这行命令，然后按回车：
    ```bash
    bash <(curl -l -s https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/main/app.sh)
    ```
    这行命令会帮你做这些事：
    * `curl -sSL '...' -o app.sh`: 从指定的网址静默下载 `app.sh` 脚本，并把它存到你当前的文件夹里。
    * `chmod +x app.sh`: 给刚下载的 `app.sh` 脚本加上执行权限。
    * `./app.sh`: 运行 `app.sh` 脚本。

3.  **跟着提示走**: `app.sh` 脚本启动后，就会开始问你问题啦。

## 配置步骤详解 (通用)

无论你用的是 Windows 还是 macOS 脚本，配置的步骤都差不多：

### 1. 准备好“原料”

脚本会自动去 GitHub 上帮你把最新的 `app.js` 和 `package.json` 这两个文件下载下来。
* `app.js` 的下载地址: `https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/app.js`
* `package.json` 的下载地址: `https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json`

它们会被保存在你运行脚本的那个文件夹里。

### 2. 设置基本参数

接下来，脚本会问你要几个基本信息：

* **你的域名 (Domain)**: 比如 `yourdomain.freewebhostmost.com`。这个域名会用在 VLESS 链接里，也会写进 `app.js`。
* **UUID**: 你可以填一个你自己的 UUID，如果懒得想，直接按回车，脚本会帮你生成一个独一无二的 (Windows 用 `[guid]::NewGuid()`, macOS 用 `uuidgen`)。
* **app.js 监听的端口号 (Port)**: 就是 `app.js` 里的 HTTP 服务器用哪个端口。不想填的话，按回车，脚本会在 10000 到 65535 之间随便给你选一个。
* **自定义订阅路径**: 你可以指定一个喜欢的订阅路径 (比如 `mysub`)，如果留空，脚本会自动生成一个随机的路径 (比如 `/AbCd123X`)。输入的路径请不要带开头的 `/`。

填完这些，脚本就会把 `app.js` 文件里的对应内容改好，然后告诉你配置好的信息，还有你的 VLESS 订阅链接（格式是 `https://你的域名/你的订阅路径`）。

### 3. (可选步骤) 配置 Nezha 监控

基本设置搞定后，脚本会问你要不要顺便把 Nezha 监控也配上。

* 如果你选 **是 (Y 或 y)**，它会继续问你：
    * **NEZHA_SERVER**: 你的 Nezha 面板服务器地址 (比如 `nezha.yourdomain.com`)。
    * **NEZHA_PORT**: Nezha 面板的端口号 (比如 `443` 或者 `5555`)。
    * **NEZHA_KEY**: Nezha 面板的密钥 (如果你的面板不需要密钥，这里可以直接按回车跳过)。
    然后脚本会把这些信息也更新到 `app.js` 文件里。
* 如果你选 **否 (N 或 n)**，那就跳过这一步，没问题！

## 最后你会得到这些文件

脚本跑完后，你运行脚本的那个文件夹里，会生成或者修改好下面这些文件：

* `app.js`: 根据你的回答修改好的核心程序文件。
* `package.json`: 项目的依赖说明文件，是从 GitHub 下载的。
* `app.ps1` (Windows 用户) 或 `app.sh` (macOS 用户): PowerShell 或 Bash 脚本它自己 (如果你是用快速命令运行的，或者你手动保存的文件名就是这个)。

## 把文件传到 Webhostmost

配置都弄好了，现在你需要把下面这两个文件传到你的 Webhostmost 主机上：

* `app.js`
* `package.json`

**传到哪里呢？建议是这个路径**: `domains/你输入的域名/public_html/`

把上面那两个文件传到这个文件夹里就行。

## 温馨提示

* **文件编码**: 如果你用文本编辑器打开修改后的 `app.js` 文件，发现里面是乱码，别慌！大概率是你的编辑器没用 UTF-8 编码打开它。试试在编辑器的设置里把它改成用 **UTF-8** 编码查看。脚本处理和保存 `app.js` 的时候会尽量保持 UTF-8 编码。
* **特定于 macOS 的 `sed` 命令**: macOS 上的 `sed` (BSD版本) 和 Linux 上的 `sed` (GNU版本) 在处理正则表达式时可能有些细微差别。`app.sh` 脚本已经针对 macOS 的 `sed` 进行了一些适配，但如果遇到奇怪的替换问题，这可能是一个需要检查的地方。Windows 版本的 `app.ps1` 使用 PowerShell 内置的替换功能，不存在这个问题。
* **出错了?**: 脚本里加了一些简单的错误检查。万一下载文件或者改文件的时候出了问题，脚本会告诉你，然后可能会停下来。如果 `app.js` 被意外清空，请检查脚本是否有错误提示，并确保源 `app.js` 文件结构没有大的变动。
* **`app.js` 的“小秘密”**: 脚本修改 `app.js` 的时候，是按照特定格式来找默认值的 (比如 `const UUID = process.env.UUID || '默认值';` 这种)。如果源头 `app.js` 文件的结构变动太大，脚本可能就找不到地方改了，那时候可能需要调整一下脚本里的查找规则。

---

希望这份指南能让你用起这个配置脚本更顺手！祝你玩得开心！
