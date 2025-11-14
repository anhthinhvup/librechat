#!/bin/bash
# Script to create librechat.yaml file on server if it doesn't exist

LIBRECHAT_DIR="/opt/librechat"

if [ ! -f "$LIBRECHAT_DIR/librechat.yaml" ]; then
    echo "Creating librechat.yaml from example..."
    
    # Check if example file exists
    if [ -f "$LIBRECHAT_DIR/librechat.example.yaml" ]; then
        cp "$LIBRECHAT_DIR/librechat.example.yaml" "$LIBRECHAT_DIR/librechat.yaml"
        echo "✓ Created librechat.yaml from example file"
    else
        # Create minimal librechat.yaml
        cat > "$LIBRECHAT_DIR/librechat.yaml" << 'EOF'
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
        echo "✓ Created minimal librechat.yaml file"
    fi
    
    # Set proper permissions
    chmod 644 "$LIBRECHAT_DIR/librechat.yaml"
    echo "✓ File created successfully at $LIBRECHAT_DIR/librechat.yaml"
else
    echo "✓ librechat.yaml already exists"
fi




