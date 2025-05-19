#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (反馈TG): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By (核心功能实现):
#   - https://github.com/eooce
#   - https://github.com/qwer-search
# Version: 2.4.5.sh (macOS - sed delimiter change & error handling)

# --- 颜色定义 ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m' # No Color

echo ""
echo -e "${COLOR_MAGENTA}欢迎使用 Webhostmost-ws-nodejs 配置脚本!${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}此脚本由 Joey (joeyblog.net) 提供，用于简化配置流程。${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}核心功能基于 eooce 和 qwer-search 的工作。${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}如果您对此脚本有任何反馈，请通过 Telegram 联系: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

echo -e "${COLOR_GREEN}==================== Webhostmost-ws-nodejs 配置生成脚本 ====================${COLOR_RESET}"

# --- 全局变量 ---
current_path=$(pwd)
app_js_file_name="app.js"
package_json_file_name="package.json"
app_js_path="$current_path/$app_js_file_name"
package_json_path="$current_path/$package_json_file_name"
sed_error_log="/tmp/sed_error.log" # Temporary file for sed errors

app_js_url="https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
package_json_url="https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

# --- 函数定义 ---

# 下载文件函数
download_file() {
    local url="$1"
    local output_path="$2"
    local file_name="$3"

    echo "正在下载 $file_name (来自 $url)..."
    if curl -fsSL -o "$output_path" "$url"; then
        echo -e "${COLOR_GREEN}$file_name 下载成功。${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}下载 $file_name 失败。错误码: $?${COLOR_RESET}"
        echo -e "${COLOR_RED}请检查网络连接或 URL 是否正确: $url${COLOR_RESET}"
        return 1
    fi
    return 0
}

# 修改 app.js 中的配置项函数
update_app_js_config() {
    local filepath="$1"
    local conf_name="$2"
    local conf_value="$3"
    local sed_script_template="$4" # Example: "s#PAT#REP#g"
    local original_content
    local new_content
    local sed_exit_status

    if [[ ! -f "$filepath" ]]; then
        echo -e "${COLOR_RED}错误: $app_js_file_name 文件未找到于路径 '$filepath'。无法修改 '$conf_name'。${COLOR_RESET}"
        return 1
    fi

    # 为sed替换操作转义特殊字符: & \ # (new delimiter) 以及 /
    local escaped_conf_value=$(echo "$conf_value" | sed -e 's/[\&##]/\\&/g' -e 's/\//\\\//g' -e 's/\\/\\\\/g')


    # 将模板中的 {VALUE_PLACEHOLDER} 替换为转义后的配置值
    # Using # as delimiter for this inner sed as well, assuming sed_script_template doesn't use # for its own structure
    local final_sed_script=$(echo "$sed_script_template" | sed "s#{VALUE_PLACEHOLDER}#$escaped_conf_value#g")
    
    original_content=$(cat "$filepath")
    # 使用 printf '%s' 避免 echo 可能引入的额外换行或处理反斜杠
    # Redirect sed stderr to a log file
    new_content=$(printf '%s' "$original_content" | sed -E "$final_sed_script" 2>"$sed_error_log")
    sed_exit_status=$?

    if [ $sed_exit_status -ne 0 ]; then
        echo -e "${COLOR_RED}错误: sed 命令在修改 '$conf_name' 时失败，退出状态码: $sed_exit_status.${COLOR_RESET}"
        if [[ -s "$sed_error_log" ]]; then # Check if log file is not empty
             echo -e "${COLOR_RED}Sed 错误信息: $(cat "$sed_error_log")${COLOR_RESET}"
        fi
        rm -f "$sed_error_log" # Clean up log file
        return 1 # Indicate failure
    fi
    rm -f "$sed_error_log" # Clean up log file if successful

    if [[ "$original_content" == "$new_content" ]]; then
        echo -e "${COLOR_YELLOW}警告: 配置项 '$conf_name' 在 $app_js_file_name 中未找到匹配的模式或值未改变。${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}使用的sed命令模板: $sed_script_template${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}实际执行的sed脚本: $final_sed_script${COLOR_RESET}"
    else
        # 使用 printf '%s' 避免 echo 可能引入的额外换行或处理反斜杠
        printf '%s' "$new_content" > "$filepath"
        echo -e "${COLOR_GREEN}$app_js_file_name 中的 '$conf_name' 已更新为 '$conf_value'。${COLOR_RESET}"
    fi
    return 0
}

# 基本配置函数
invoke_basic_configuration() {
    echo -e "\n${COLOR_YELLOW}--- 正在配置基本部署参数 (UUID, Domain, Port, Subscription Path) ---${COLOR_RESET}"

    while true; do
        read -p "请输入您的域名（例如：yourdomain.freewebhostmost.com）: " domain_val
        if [[ -n "$domain_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}域名不能为空，请重新输入。${COLOR_RESET}"
        fi
    done
    DOMAIN_CONFIGURED="$domain_val"

    read -p "请输入 UUID（留空则自动生成）: " uuid_val
    if [[ -z "$uuid_val" ]]; then
        uuid_val=$(uuidgen) 
        echo -e "${COLOR_CYAN}已自动生成 UUID: $uuid_val${COLOR_RESET}"
    fi
    UUID_CONFIGURED="$uuid_val"

    read -p "请输入 app.js 的 HTTP 服务器监听端口（留空则随机生成 10000-65535）: " vl_port_val
    if [[ -z "$vl_port_val" ]]; then
        vl_port_val=$((RANDOM % (65535 - 10000 + 1) + 10000))
        echo -e "${COLOR_CYAN}已自动生成端口号: $vl_port_val${COLOR_RESET}"
    elif ! [[ "$vl_port_val" =~ ^[0-9]+$ ]] || [ "$vl_port_val" -lt 1 ] || [ "$vl_port_val" -gt 65535 ]; then
        echo -e "${COLOR_YELLOW}输入的端口号无效，将自动生成一个端口号。${COLOR_RESET}"
        vl_port_val=$((RANDOM % (65535 - 10000 + 1) + 10000))
        echo -e "${COLOR_CYAN}已自动生成端口号: $vl_port_val${COLOR_RESET}"
    fi
    PORT_CONFIGURED="$vl_port_val"

    read -p "请输入自定义订阅路径 (例如 sub, mypath。留空则自动生成，不要以 / 开头): " subscription_path_input
    local subscription_path_val=""
    if [[ -z "$subscription_path_input" ]]; then
        local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        subscription_path_val="/$random_path_name"
        echo -e "${COLOR_CYAN}已自动生成订阅路径: $subscription_path_val${COLOR_RESET}"
    else
        local cleaned_path=$(echo "$subscription_path_input" | sed -E 's#^/+##; s#/*$##')
        if [[ -z "$cleaned_path" ]]; then 
            local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
            subscription_path_val="/$random_path_name"
            echo -e "${COLOR_CYAN}输入的路径无效，已自动生成订阅路径: $subscription_path_val${COLOR_RESET}"
        else
            subscription_path_val="/$cleaned_path"
        fi
    fi
    echo -e "${COLOR_CYAN}最终订阅路径将是: $subscription_path_val${COLOR_RESET}"
    SUB_PATH_CONFIGURED="$subscription_path_val"
    
    echo "正在修改 $app_js_file_name 中的基本参数..."
    # 使用 # 作为 sed 分隔符
    update_app_js_config "$app_js_path" "UUID" "$uuid_val" \
        "s#(const UUID = process\.env\.UUID \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "DOMAIN" "$domain_val" \
        "s#(const DOMAIN = process\.env\.DOMAIN \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "PORT" "$vl_port_val" \
        "s#(const port = process\.env\.PORT \|\| )([0-9]*)(;)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    
    update_app_js_config "$app_js_path" "Subscription URL Path" "$subscription_path_val" \
        "s#(else[[:blank:]]+if[[:blank:]]*\([[:blank:]]*req\.url[[:blank:]]*===[[:blank:]]*')(\/[^']+)(')#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    
    return 0
}

# Nezha 配置函数
invoke_nezha_configuration() {
    echo -e "\n${COLOR_YELLOW}--- 正在配置 Nezha 监控参数 ---${COLOR_RESET}"

    while true; do
        read -p "请输入 NEZHA_SERVER (例如：nezha.yourdomain.com): " nezha_server_val
        if [[ -n "$nezha_server_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}NEZHA_SERVER 不能为空，请重新输入。${COLOR_RESET}"
        fi
    done
    NEZHA_SERVER_CONFIGURED="$nezha_server_val"

    while true; do
        read -p "请输入 NEZHA_PORT (例如：443 或 5555): " nezha_port_val
        if [[ -n "$nezha_port_val" ]] && [[ "$nezha_port_val" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}NEZHA_PORT 不能为空且必须为数字，请重新输入。${COLOR_RESET}"
        fi
    done
    NEZHA_PORT_CONFIGURED="$nezha_port_val"

    read -p "请输入 NEZHA_KEY (哪吒面板密钥，可留空): " nezha_key_val
    if [[ -z "$nezha_key_val" ]]; then
        echo -e "${COLOR_MAGENTA}提示: NEZHA_KEY 为空。${COLOR_RESET}"
    fi
    NEZHA_KEY_CONFIGURED="$nezha_key_val"
    
    echo "正在修改 $app_js_file_name 中的 Nezha 参数..."
    # 使用 # 作为 sed 分隔符
    update_app_js_config "$app_js_path" "NEZHA_SERVER" "$nezha_server_val" \
        "s#(const NEZHA_SERVER = process\.env\.NEZHA_SERVER \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "NEZHA_PORT" "$nezha_port_val" \
        "s#(const NEZHA_PORT = process\.env\.NEZHA_PORT \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "NEZHA_KEY" "$nezha_key_val" \
        "s#(const NEZHA_KEY = process\.env\.NEZHA_KEY \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1

    return 0
}

# --- 主程序逻辑 ---
basic_config_performed=false
nezha_config_performed=false
error_occurred=false

echo -e "\n${COLOR_YELLOW}准备配置文件...${COLOR_RESET}"
if ! download_file "$app_js_url" "$app_js_path" "$app_js_file_name"; then
    error_occurred=true
fi
if ! $error_occurred && ! download_file "$package_json_url" "$package_json_path" "$package_json_file_name"; then
    echo -e "${COLOR_YELLOW}警告: $package_json_file_name 下载失败，但将继续尝试配置。${COLOR_RESET}"
fi

if ! $error_occurred; then
    if invoke_basic_configuration; then
        basic_config_performed=true
        echo -e "\n${COLOR_GREEN}==================== 基本配置完成 ====================${COLOR_RESET}"
        echo -e "域名 (Domain)： ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
        echo -e "UUID： ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
        echo -e "app.js 监听端口 (Port)： ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
        echo -e "订阅路径 (Subscription Path): ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
        sub_link="https://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"
        echo -e "节点分享链接 (VLESS Subscription Link)：${COLOR_CYAN}$sub_link${COLOR_RESET}"
        echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"

        read -p "是否要继续配置 Nezha 监控参数? (Y/N): " configure_nezha_choice
        if [[ "$configure_nezha_choice" =~ ^[Yy]$ ]]; then
            if invoke_nezha_configuration; then
                nezha_config_performed=true
                echo -e "\n${COLOR_GREEN}==================== Nezha 配置完成 ====================${COLOR_RESET}"
                echo -e "NEZHA_SERVER： ${COLOR_CYAN}$NEZHA_SERVER_CONFIGURED${COLOR_RESET}"
                echo -e "NEZHA_PORT： ${COLOR_CYAN}$NEZHA_PORT_CONFIGURED${COLOR_RESET}"
                echo -e "NEZHA_KEY： ${COLOR_CYAN}$NEZHA_KEY_CONFIGURED${COLOR_RESET}"
                echo -e "${COLOR_GREEN}Nezha 参数已配置到 $app_js_file_name。${COLOR_RESET}"
                echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
            else
                 echo -e "${COLOR_RED}Nezha 配置过程中发生错误。${COLOR_RESET}"
                 # No need to set error_occurred=true here if basic config was okay and user wants to proceed
            fi
        else
            echo -e "${COLOR_YELLOW}跳过 Nezha 监控参数配置。${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_RED}基本配置过程中发生错误。${COLOR_RESET}"
        error_occurred=true
    fi
else
    echo -e "${COLOR_RED}由于文件下载失败，无法进行配置。${COLOR_RESET}"
fi

if $basic_config_performed || $nezha_config_performed; then 
    echo -e "\n${COLOR_GREEN}==================== 所有配置操作完成 ====================${COLOR_RESET}"
    echo -e "配置文件已保存至当前目录：${COLOR_CYAN}$current_path${COLOR_RESET}"
    
    if $basic_config_performed && [[ -n "$DOMAIN_CONFIGURED" ]]; then
        echo -e "${COLOR_YELLOW}您需要手动将以下文件上传到您的 Webhostmost 主机，建议的上传路径为：${COLOR_RESET}"
        echo -e "${COLOR_CYAN}  domains/$DOMAIN_CONFIGURED/public_html${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}请将以下文件上传到上述路径：${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}您需要手动将以下文件上传到您的 Webhostmost 主机的网站根目录 (例如 public_html)：${COLOR_RESET}"
    fi
    echo -e "  - $app_js_file_name"
    echo -e "  - $package_json_file_name"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    if $basic_config_performed; then
        echo -e "${COLOR_GREEN}已配置基本参数。${COLOR_RESET}"
        if [[ -n "$SUB_PATH_CONFIGURED" ]]; then
             echo -e "${COLOR_GREEN}自定义/自动生成的订阅路径为: $SUB_PATH_CONFIGURED${COLOR_RESET}"
        fi
    fi
    if $nezha_config_performed; then
        echo -e "${COLOR_GREEN}已配置 Nezha 监控参数。${COLOR_RESET}"
    fi
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}重要提示: 如果修改后的 $app_js_file_name 文件在文本编辑器中出现乱码，${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}请确保您的文本编辑器使用 UTF-8 编码来打开和查看该文件。${COLOR_RESET}"

elif $error_occurred; then 
    echo -e "\n${COLOR_RED}由于发生错误，配置未全部完成。${COLOR_RESET}"
else 
    echo -e "\n${COLOR_YELLOW}未进行任何有效配置，或配置未成功。${COLOR_RESET}"
fi

echo -e "${COLOR_GREEN}==================== 脚本操作结束 ====================${COLOR_RESET}"
ß
