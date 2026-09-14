#!/usr/bin/env bash

# ==============================================================================
# Base Agents Setup & Installation Script
# Tác giả: Senior Fullstack & DevOps Engineer
# Mục đích: Cài đặt 1 chạm toàn bộ Rules, Skills, MCP Servers & Starter Stack
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CONFIG_DIR="$HOME/.gemini/config"
GLOBAL_SKILLS_DIR="$HOME/.gemini/config/skills"
GLOBAL_MCP_CONFIG="$HOME/.gemini/config/mcp_config.json"

# Màu hiển thị console
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}   BASE AGENTS INSTALLER - 1-CLICK AI DEV SETUP                 ${NC}"
  echo -e "${BLUE}================================================================${NC}"
}

install_global() {
  echo -e "\n${YELLOW}==> [1/3] Cài đặt Global Rules vào ${GLOBAL_CONFIG_DIR}...${NC}"
  mkdir -p "${GLOBAL_CONFIG_DIR}"
  cp "${SCRIPT_DIR}/GEMINI.md" "${GLOBAL_CONFIG_DIR}/GEMINI.md"
  echo -e "${GREEN}✓ Đã đồng bộ GEMINI.md vào Global Config.${NC}"

  echo -e "\n${YELLOW}==> [2/3] Cài đặt Global Skills vào ${GLOBAL_SKILLS_DIR}...${NC}"
  mkdir -p "${GLOBAL_SKILLS_DIR}"
  if [ -d "${SCRIPT_DIR}/skills" ]; then
    cp -R "${SCRIPT_DIR}/skills/"* "${GLOBAL_SKILLS_DIR}/"
    echo -e "${GREEN}✓ Đã cài đặt toàn bộ skills ($(ls -1 "${SCRIPT_DIR}/skills" | wc -l | tr -d ' ') skills) vào Global.${NC}"
  fi

  echo -e "\n${YELLOW}==> [3/3] Cấu hình MCP Servers (CodeGraph & Obsidian)...${NC}"
  # Tự động tìm Obsidian Vault nếu có
  OBSIDIAN_VAULT_DEFAULT="$HOME/Documents/Obsidian Vault"
  if [ -f "$HOME/Library/Application Support/obsidian/obsidian.json" ]; then
    DETECTED_VAULT=$(grep -o '"path":"[^"]*' "$HOME/Library/Application Support/obsidian/obsidian.json" | head -n 1 | cut -d'"' -f4 || true)
    if [ -n "$DETECTED_VAULT" ]; then
      OBSIDIAN_VAULT_DEFAULT="$DETECTED_VAULT"
    fi
  fi

  cat << EOF > "${GLOBAL_MCP_CONFIG}"
{
  "mcpServers": {
    "codegraph": {
      "command": "$HOME/.local/bin/codegraph",
      "args": [
        "serve",
        "--mcp"
      ]
    },
    "obsidian": {
      "command": "/usr/local/bin/npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${OBSIDIAN_VAULT_DEFAULT}"
      ]
    }
  }
}
EOF
  echo -e "${GREEN}✓ Đã tạo file ${GLOBAL_MCP_CONFIG} với Obsidian Vault: ${OBSIDIAN_VAULT_DEFAULT}${NC}"
  echo -e "${GREEN}🎉 Cài đặt Global hoàn tất! Toàn bộ dự án trên máy sẽ tự động nhận rules, skills và MCP.${NC}\n"
}

install_project() {
  TARGET_DIR="$1"
  if [ -z "$TARGET_DIR" ]; then
    echo -e "${RED}Lỗi: Vui lòng truyền đường dẫn thư mục dự án cần cài đặt!${NC}"
    echo -e "Ví dụ: ./install.sh --project /Users/krylot/Documents/Projects/my-app"
    exit 1
  fi

  echo -e "\n${YELLOW}==> Cài đặt Rules & Skills vào dự án: ${TARGET_DIR}...${NC}"
  mkdir -p "${TARGET_DIR}/.agents/skills"
  mkdir -p "${TARGET_DIR}/specs"

  # Copy rules & gitignore nếu chưa có
  cp "${SCRIPT_DIR}/GEMINI.md" "${TARGET_DIR}/GEMINI.md"
  if [ ! -f "${TARGET_DIR}/.gitignore" ]; then
    cp "${SCRIPT_DIR}/.gitignore" "${TARGET_DIR}/.gitignore"
  fi

  # Copy skills vào .agents/skills của dự án
  if [ -d "${SCRIPT_DIR}/skills" ]; then
    cp -R "${SCRIPT_DIR}/skills/"* "${TARGET_DIR}/.agents/skills/"
  fi

  echo -e "${GREEN}✓ Đã copy GEMINI.md, .gitignore, specs/, và toàn bộ skills vào ${TARGET_DIR}.${NC}"
  echo -e "${GREEN}🎉 Dự án đã sẵn sàng làm việc với AI Agent!${NC}\n"
}

print_usage() {
  echo "Cách sử dụng:"
  echo "  ./install.sh --global                  Cài đặt Rules, Skills & MCP toàn cục cho toàn máy"
  echo "  ./install.sh --project /path/to/proj   Cài đặt Rules & Skills cục bộ cho 1 dự án cụ thể"
  echo "  ./install.sh --all /path/to/proj       Thực thi cả Global và Project Setup"
  echo ""
}

print_header

case "$1" in
  --global|-g)
    install_global
    ;;
  --project|-p)
    install_project "$2"
    ;;
  --all|-a)
    install_global
    install_project "$2"
    ;;
  *)
    print_usage
    ;;
esac
