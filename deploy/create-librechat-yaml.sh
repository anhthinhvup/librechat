#!/bin/bash
# Quick script to create librechat.yaml on server

cat > /opt/librechat/librechat.yaml << 'EOF'
version: 1.2.1
cache: true
interface:
  customWelcome: Welcome to LibreChat! Enjoy your experience.
  fileSearch: true
  endpointsMenu: true
  modelSelect: true
  parameters: true
  sidePanel: true
  presets: true
  prompts: true
  bookmarks: true
  multiConvo: true
  agents: true
  fileCitations: true
registration:
  socialLogins: ['google']
endpoints:
  openAI:
    apiKey: ${OPENAI_API_KEY}
    models:
      default:
        - gpt-4o-mini-2024-07-18
        - gpt-4.1-mini
        - gpt-5-nano-2025-08-07
      fetch: true
    titleConvo: true
    titleModel: gpt-4o-mini-2024-07-18
    summarize: true
    summaryModel: gpt-4o-mini-2024-07-18
  custom: []
EOF

chmod 644 /opt/librechat/librechat.yaml
echo "✓ File librechat.yaml đã được tạo thành công!"

