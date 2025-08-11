#!/bin/bash

#===============================================================================
# GitHub 推送脚本
# 功能: 简单快速地推送代码到 GitHub 主分支
# 作者: npz
# 版本: 1.0
#===============================================================================

#===============================================================================
# 颜色输出函数
#===============================================================================
print_blue() {
    echo -e "\033[0;34m$1\033[0m"
}

print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

print_header() {
    echo -e "\033[1;36m==== $1 ====\033[0m"
}

#===============================================================================
# 检查 Git 仓库状态
#===============================================================================
check_git_status() {
    print_header "检查仓库状态"
    
    # 检查是否在 Git 仓库中
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_red "错误: 当前目录不是 Git 仓库"
        return 1
    fi
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        print_yellow "⚠ 检测到未提交的更改:"
        git status --porcelain
        echo
        print_yellow "建议先提交更改再推送"
        read -p "是否继续推送? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_blue "推送已取消"
            return 1
        fi
    else
        print_green "✓ 工作目录干净，没有未提交的更改"
    fi
    
    # 显示当前分支信息
    local current_branch
    current_branch=$(git branch --show-current)
    print_blue "当前分支: $current_branch"
    
    # 显示最近的提交
    print_blue "最近提交:"
    git log --oneline -3
    echo
    
    return 0
}

#===============================================================================
# 执行推送操作到主分支
#===============================================================================
perform_push() {
    print_header "推送到 GitHub 主分支"
    
    local current_branch
    current_branch=$(git branch --show-current)
    
    print_blue "正在推送分支 '$current_branch' 到远程仓库的 main 分支..."
    
    # 执行推送
    if git push origin HEAD:refs/heads/main; then
        print_green "✓ 推送成功完成！"
        echo
        print_blue "推送信息:"
        print_blue "  本地分支: $current_branch"
        print_blue "  远程分支: main"
        print_blue "  远程仓库: origin"
        
        # 显示远程仓库 URL
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null)
        if [ -n "$remote_url" ]; then
            print_blue "  仓库地址: $remote_url"
        fi
        
        return 0
    else
        print_red "✗ 推送失败！"
        print_yellow "可能的原因:"
        print_yellow "  - 网络连接问题"
        print_yellow "  - 权限不足"
        print_yellow "  - 远程分支有新的提交（需要先拉取）"
        print_yellow "  - 仓库地址配置错误"
        echo
        print_yellow "建议操作:"
        print_yellow "  1. 检查网络连接"
        print_yellow "  2. 确认 GitHub 认证信息"
        print_yellow "  3. 尝试: git pull origin main"
        print_yellow "  4. 检查远程仓库配置: git remote -v"
        
        return 1
    fi
}

#===============================================================================
# 显示帮助信息
#===============================================================================
show_help() {
    print_blue "GitHub 推送脚本"
    echo
    print_blue "用法:"
    print_blue "  $0                    # 推送当前分支到远程 main 分支"
    print_blue "  $0 -h, --help         # 显示帮助信息"
    echo
    print_blue "功能:"
    print_blue "  - 检查仓库状态和未提交更改"
    print_blue "  - 安全地推送代码到 GitHub main 分支"
    print_blue "  - 提供详细的操作反馈"
    echo
    print_blue "注意事项:"
    print_blue "  - 推送前会检查工作目录状态"
    print_blue "  - 如有未提交更改会提醒用户"
    print_blue "  - 推送目标固定为远程 main 分支"
}

#===============================================================================
# 主执行函数
#===============================================================================
main() {
    # 处理命令行参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        "")
            # 默认行为：执行推送
            print_header "GitHub 推送工具"
            print_blue "准备将代码推送到远程仓库..."
            echo
            
            # 检查仓库状态
            if ! check_git_status; then
                exit 1
            fi
            
            # 执行推送
            if ! perform_push; then
                exit 1
            fi
            
            echo
            print_green "🎉 推送操作完成！"
            ;;
        *)
            print_red "未知参数: $1"
            echo
            print_blue "使用 '$0 --help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"