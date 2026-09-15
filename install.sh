#!/usr/bin/env bash

# ==============================================================================
# Base Agents Universal Installer (macOS, CentOS 9, Amazon Linux, Ubuntu)
# Tác giả: Senior Fullstack & DevOps Engineer
# Hỗ trợ: ec2-user, centos, ubuntu, macOS
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
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}   BASE AGENTS UNIVERSAL INSTALLER                              ${NC}"
  echo -e "${BLUE}   Supports: macOS, CentOS 9, Amazon Linux (ec2-user), Ubuntu  ${NC}"
  echo -e "${BLUE}================================================================${NC}"
}

# 1. Phát hiện hệ điều hành và gói quản trị
detect_os() {
  OS_TYPE="unknown"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE="$ID"
  fi
  echo -e "${CYAN}==> Hệ điều hành phát hiện: ${OS_TYPE} (User: $(whoami))${NC}"
}

# 2. Đảm bảo Node.js & npx khả dụng
ensure_nodejs() {
  echo -e "\n${YELLOW}==> [1/5] Kiểm tra Node.js & npx...${NC}"
  if ! command -v node &> /dev/null || ! command -v npx &> /dev/null; then
    echo -e "${YELLOW}Chưa tìm thấy Node.js/npx. Đang tiến hành hướng dẫn/cài đặt...${NC}"
    if [ "$OS_TYPE" == "centos" ] || [ "$OS_TYPE" == "rhel" ] || [ "$OS_TYPE" == "almalinux" ] || [ "$OS_TYPE" == "rocky" ] || [ "$OS_TYPE" == "amzn" ]; then
      echo -e "${CYAN}Đang cài đặt Node.js trên RedHat/CentOS/Amazon Linux...${NC}"
      sudo dnf module install -y nodejs:20 || sudo yum install -y nodejs || {
        echo -e "${YELLOW}Cài đặt qua NVM fallback...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
      }
    elif [ "$OS_TYPE" == "ubuntu" ] || [ "$OS_TYPE" == "debian" ]; then
      sudo apt-get update && sudo apt-get install -y nodejs npm
    elif [ "$OS_TYPE" == "macos" ]; then
      echo -e "${RED}Vui lòng cài đặt Node.js trên macOS qua: brew install node hoặc tải từ nodejs.org${NC}"
      exit 1
    fi
  fi

  NODE_BIN="$(command -v node || echo "")"
  NPX_BIN="$(command -v npx || echo "")"
  echo -e "${GREEN}✓ Node.js: ${NODE_BIN} | npx: ${NPX_BIN}${NC}"
}

# 3. Cài đặt CodeGraph CLI
ensure_codegraph() {
  echo -e "\n${YELLOW}==> [2/5] Kiểm tra & Cài đặt CodeGraph CLI...${NC}"
  
  # Đảm bảo ~/.local/bin nằm trong PATH
  mkdir -p "$HOME/.local/bin"
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    fi
  fi

  if ! command -v codegraph &> /dev/null && [ ! -f "$HOME/.local/bin/codegraph" ]; then
    echo -e "${CYAN}Đang tải và cài đặt CodeGraph CLI từ installer chính thức...${NC}"
    curl -fsSL https://codegraph.dev/install.sh | bash || {
      echo -e "${YELLOW}Cảnh báo: Không thể tải từ codegraph.dev, thử qua npm global...${NC}"
      npm install -g codegraph 2>/dev/null || true
    }
  fi

  CODEGRAPH_BIN="$(command -v codegraph || echo "$HOME/.local/bin/codegraph")"
  echo -e "${GREEN}✓ CodeGraph CLI: ${CODEGRAPH_BIN}${NC}"
}

# 4. Xác định / Khởi tạo Obsidian Vault
ensure_obsidian_vault() {
  echo -e "\n${YELLOW}==> [3/5] Thiết lập Obsidian Vault Knowledge Base...${NC}"
  CUSTOM_VAULT="$1"
  VAULT_DIR=""

  if [ -n "$CUSTOM_VAULT" ]; then
    VAULT_DIR="$CUSTOM_VAULT"
  elif [ "$OS_TYPE" == "macos" ] && [ -f "$HOME/Library/Application Support/obsidian/obsidian.json" ]; then
    DETECTED_VAULT=$(grep -o '"path":"[^"]*' "$HOME/Library/Application Support/obsidian/obsidian.json" | head -n 1 | cut -d'"' -f4 || true)
    [ -n "$DETECTED_VAULT" ] && VAULT_DIR="$DETECTED_VAULT"
  fi

  if [ -z "$VAULT_DIR" ]; then
    if [ "$OS_TYPE" == "macos" ]; then
      VAULT_DIR="$HOME/Documents/Obsidian Vault"
    else
      # Mặc định trên Linux / VPS (CentOS 9, ec2-user)
      VAULT_DIR="$HOME/obsidian_vault"
    fi
  fi

  mkdir -p "${VAULT_DIR}/Projects"
  echo -e "${GREEN}✓ Obsidian Vault Path: ${VAULT_DIR} (Projects folder ready)${NC}"
}

# 5. Cài đặt Global Rules, Skills & Cấu hình MCP
install_global() {
  CUSTOM_VAULT="$1"
  detect_os
  ensure_nodejs
  ensure_codegraph
  ensure_obsidian_vault "$CUSTOM_VAULT"

  echo -e "\n${YELLOW}==> [4/5] Đồng bộ Global Rules & Skills...${NC}"
  mkdir -p "${GLOBAL_CONFIG_DIR}"
  cp "${SCRIPT_DIR}/GEMINI.md" "${GLOBAL_CONFIG_DIR}/GEMINI.md"
  echo -e "${GREEN}✓ Đã đồng bộ GEMINI.md vào ${GLOBAL_CONFIG_DIR}/GEMINI.md${NC}"

  mkdir -p "${GLOBAL_SKILLS_DIR}"
  if [ -d "${SCRIPT_DIR}/skills" ]; then
    cp -R "${SCRIPT_DIR}/skills/"* "${GLOBAL_SKILLS_DIR}/"
    echo -e "${GREEN}✓ Đã cài đặt toàn bộ skills ($(ls -1 "${SCRIPT_DIR}/skills" | wc -l | tr -d ' ') skills) vào Global.${NC}"
  fi

  echo -e "\n${YELLOW}==> [5/5] Cấu hình MCP Servers (CodeGraph & Obsidian)...${NC}"
  NPX_EXEC="$(command -v npx || echo "npx")"
  CODEGRAPH_EXEC="$(command -v codegraph || echo "$HOME/.local/bin/codegraph")"

  cat << EOF > "${GLOBAL_MCP_CONFIG}"
{
  "mcpServers": {
    "codegraph": {
      "command": "${CODEGRAPH_EXEC}",
      "args": [
        "serve",
        "--mcp"
      ]
    },
    "obsidian": {
      "command": "${NPX_EXEC}",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${VAULT_DIR}"
      ]
    }
  }
}
EOF

  echo -e "${GREEN}✓ Đã ghi cấu hình vào ${GLOBAL_MCP_CONFIG}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${GREEN}🎉 CÀI ĐẶT HOÀN TẤT THÀNH CÔNG CHO HỆ ĐIỀU HÀNH: ${OS_TYPE}!${NC}"
  echo -e "${GREEN}   - CodeGraph: ${CODEGRAPH_EXEC}${NC}"
  echo -e "${GREEN}   - Obsidian Vault: ${VAULT_DIR}${NC}"
  echo -e "${GREEN}   - Global Rules: ${GLOBAL_CONFIG_DIR}/GEMINI.md${NC}"
  echo -e "${YELLOW}💡 Tip: Sử dụng '!team' để gọi Multi Agent Skill${NC}"
  echo -e "${BLUE}================================================================${NC}\n"
}

# 6. Cài đặt vào dự án cụ thể
install_project() {
  TARGET_DIR="$1"
  if [ -z "$TARGET_DIR" ]; then
    echo -e "${RED}Lỗi: Vui lòng truyền đường dẫn thư mục dự án cần cài đặt!${NC}"
    echo -e "Ví dụ: ./install.sh --project /path/to/my-new-project"
    exit 1
  fi

  echo -e "\n${YELLOW}==> Cài đặt Rules & Skills vào dự án: ${TARGET_DIR}...${NC}"
  mkdir -p "${TARGET_DIR}/.agents/skills"
  mkdir -p "${TARGET_DIR}/specs"
  touch "${TARGET_DIR}/specs/.gitkeep"


  cp "${SCRIPT_DIR}/GEMINI.md" "${TARGET_DIR}/GEMINI.md"
  if [ ! -f "${TARGET_DIR}/.gitignore" ]; then
    cp "${SCRIPT_DIR}/.gitignore" "${TARGET_DIR}/.gitignore"
  else
    if ! grep -q '\.codegraph/' "${TARGET_DIR}/.gitignore" 2>/dev/null; then
      echo -e "\n# CodeGraph Index DB\n.codegraph/" >> "${TARGET_DIR}/.gitignore"
    fi
  fi

  if [ -d "${SCRIPT_DIR}/skills" ]; then
    cp -R "${SCRIPT_DIR}/skills/"* "${TARGET_DIR}/.agents/skills/"
  fi

  # Khởi tạo CodeGraph index cho dự án nếu có CLI
  CODEGRAPH_BIN="$(command -v codegraph || echo "$HOME/.local/bin/codegraph")"
  if [ -x "$CODEGRAPH_BIN" ]; then
    if [ ! -d "${TARGET_DIR}/.codegraph" ]; then
      echo -e "${CYAN}Khởi tạo CodeGraph index cho dự án tại: ${TARGET_DIR}...${NC}"
      (cd "${TARGET_DIR}" && "$CODEGRAPH_BIN" init 2>/dev/null || true)
      echo -e "${GREEN}✓ Đã khởi tạo thư mục .codegraph/ cho dự án.${NC}"
    else
      echo -e "${GREEN}✓ Đã phát hiện thư mục .codegraph/ trong dự án.${NC}"
    fi
  else
    echo -e "${YELLOW}Lưu ý: Chưa phát hiện CodeGraph CLI. Hãy chạy './install.sh --global' để kích hoạt CodeGraph.${NC}"
  fi

  echo -e "${GREEN}✓ Đã copy GEMINI.md, .gitignore, specs/, skills và cấu hình CodeGraph vào ${TARGET_DIR}.${NC}"
  echo -e "${GREEN}🎉 Dự án đã sẵn sàng làm việc với AI Agent!${NC}"
  echo -e "${YELLOW}💡 Tip: Sử dụng '!team' để gọi Multi Agent Skill${NC}\n"
}

print_usage() {
  echo "Cách sử dụng:"
  echo "  ./install.sh --global [vault_path]     Cài đặt Rules, Skills, CodeGraph CLI & Obsidian MCP toàn cục"
  echo "  ./install.sh --project /path/to/proj  Cài đặt Rules & Skills cục bộ cho 1 dự án cụ thể"
  echo "  ./install.sh --all /path/to/proj      Thực thi cả Global (CodeGraph, Obsidian) và Project Setup"
  echo ""
  echo "Ví dụ trên VPS (CentOS 9 / ec2-user / Ubuntu):"
  echo "  git clone git@github-kyhuuhai:kyhuuhai/base_agents.git"
  echo "  cd base_agents && ./install.sh --global"
}

print_header

case "$1" in
  --global|-g)
    install_global "$2"
    ;;
  --project|-p)
    install_project "$2"
    ;;
  --all|-a)
    install_global "$3"
    install_project "$2"
    ;;
  *)
    print_usage
    ;;
esac
