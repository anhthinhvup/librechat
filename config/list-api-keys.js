const path = require('path');
const fs = require('fs');
const { silentExit } = require('./helpers');

// Map các API key providers
const API_KEY_PROVIDERS = {
  OPENAI_API_KEY: 'OpenAI (GPT-4, GPT-3.5, etc.)',
  ANTHROPIC_API_KEY: 'Anthropic (Claude)',
  GOOGLE_API_KEY: 'Google (Gemini)',
  AZURE_OPENAI_API_KEY: 'Azure OpenAI',
  GROQ_API_KEY: 'Groq',
  MISTRAL_API_KEY: 'Mistral',
  OPENROUTER_KEY: 'OpenRouter',
};

/**
 * Ẩn một phần API key để hiển thị an toàn
 */
function maskApiKey(apiKey) {
  if (!apiKey || apiKey.length < 8) {
    return '****';
  }
  const visibleLength = 4;
  const hiddenLength = apiKey.length - visibleLength;
  return apiKey.substring(0, visibleLength) + '*'.repeat(Math.min(hiddenLength, 20)) + apiKey.substring(apiKey.length - 4);
}

/**
 * Đọc file .env và parse các API keys
 */
function parseEnvFile(envPath) {
  try {
    if (!fs.existsSync(envPath)) {
      console.red(`Error: File .env not found at ${envPath}`);
      silentExit(1);
    }

    const content = fs.readFileSync(envPath, 'utf8');
    const lines = content.split('\n');
    const apiKeys = {};

    lines.forEach((line) => {
      // Bỏ qua comment và dòng trống
      if (line.trim().startsWith('#') || line.trim() === '') {
        return;
      }

      // Parse dòng KEY=value
      const match = line.match(/^([A-Z_]+)\s*=\s*(.+)$/);
      if (match) {
        const key = match[1];
        const value = match[2].trim();
        
        if (API_KEY_PROVIDERS[key]) {
          apiKeys[key] = value;
        }
      }
    });

    return apiKeys;
  } catch (error) {
    console.red(`Error reading .env file: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Main function
 */
(function () {
  console.purple('--------------------------');
  console.purple('Danh sách API Keys đã cấu hình');
  console.purple('--------------------------');

  // Xác định đường dẫn file .env
  // Nếu chạy từ Docker container, file .env ở /app/.env
  // Nếu chạy từ host, file .env ở thư mục gốc dự án
  const isDocker = process.env.NODE_ENV === 'production' || fs.existsSync('/app/.env');
  const envPath = isDocker 
    ? '/app/.env' 
    : path.resolve(__dirname, '..', '.env');
  const apiKeys = parseEnvFile(envPath);

  const configuredKeys = Object.keys(apiKeys);
  const allProviders = Object.keys(API_KEY_PROVIDERS);

  if (configuredKeys.length === 0) {
    console.orange('\n⚠ Chưa có API key nào được cấu hình.');
    console.cyan('\nĐể thêm API key, sử dụng lệnh:');
    console.white('   npm run add-api-key');
    console.white('   hoặc');
    console.white('   docker-compose exec api npm run add-api-key');
    silentExit(0);
  }

  console.green('\n✓ Các API Keys đã cấu hình:\n');
  
  configuredKeys.forEach((key) => {
    const description = API_KEY_PROVIDERS[key];
    const maskedKey = maskApiKey(apiKeys[key]);
    console.cyan(`  ${key.padEnd(25)} : ${maskedKey}`);
    console.gray(`    ${description}`);
    console.log('');
  });

  // Hiển thị các providers chưa được cấu hình
  const unconfigured = allProviders.filter((key) => !apiKeys[key]);
  if (unconfigured.length > 0) {
    console.orange('\n⚠ Các API Keys chưa được cấu hình:');
    unconfigured.forEach((key) => {
      console.gray(`   - ${key.padEnd(25)} : ${API_KEY_PROVIDERS[key]}`);
    });
    console.cyan('\nĐể thêm API key, sử dụng lệnh:');
    console.white('   npm run add-api-key <provider> <api_key>');
  }

  console.purple('\n--------------------------\n');
  silentExit(0);
})();

process.on('uncaughtException', (err) => {
  console.error('Có lỗi xảy ra:');
  console.error(err);
  process.exit(1);
});

