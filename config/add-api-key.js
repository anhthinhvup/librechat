const path = require('path');
const fs = require('fs');
const { askQuestion, silentExit } = require('./helpers');

// Map các API key providers
const API_KEY_PROVIDERS = {
  openai: {
    key: 'OPENAI_API_KEY',
    description: 'OpenAI API Key (GPT-4, GPT-3.5, etc.)',
    envVar: 'OPENAI_API_KEY',
  },
  anthropic: {
    key: 'ANTHROPIC_API_KEY',
    description: 'Anthropic API Key (Claude)',
    envVar: 'ANTHROPIC_API_KEY',
  },
  google: {
    key: 'GOOGLE_API_KEY',
    description: 'Google API Key (Gemini)',
    envVar: 'GOOGLE_API_KEY',
  },
  azure_openai: {
    key: 'AZURE_OPENAI_API_KEY',
    description: 'Azure OpenAI API Key',
    envVar: 'AZURE_OPENAI_API_KEY',
  },
  groq: {
    key: 'GROQ_API_KEY',
    description: 'Groq API Key',
    envVar: 'GROQ_API_KEY',
  },
  mistral: {
    key: 'MISTRAL_API_KEY',
    description: 'Mistral API Key',
    envVar: 'MISTRAL_API_KEY',
  },
  openrouter: {
    key: 'OPENROUTER_KEY',
    description: 'OpenRouter API Key',
    envVar: 'OPENROUTER_KEY',
  },
};

/**
 * Đọc file .env
 */
function readEnvFile(envPath) {
  try {
    if (!fs.existsSync(envPath)) {
      console.red(`Error: File .env not found at ${envPath}`);
      console.orange('Please make sure you are running this script from the project root directory.');
      silentExit(1);
    }
    return fs.readFileSync(envPath, 'utf8');
  } catch (error) {
    console.red(`Error reading .env file: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Ghi file .env
 */
function writeEnvFile(envPath, content) {
  try {
    fs.writeFileSync(envPath, content, 'utf8');
    console.green('✓ File .env đã được cập nhật thành công!');
  } catch (error) {
    console.red(`Error writing .env file: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Cập nhật API key trong file .env
 */
function updateApiKey(envContent, providerKey, apiKey) {
  const lines = envContent.split('\n');
  let updated = false;
  const provider = API_KEY_PROVIDERS[providerKey];

  if (!provider) {
    console.red(`Error: Provider "${providerKey}" không được hỗ trợ`);
    return envContent;
  }

  const searchPattern = new RegExp(`^#?\\s*${provider.envVar}\\s*=`);
  const newLine = `${provider.envVar}=${apiKey}`;

  for (let i = 0; i < lines.length; i++) {
    if (searchPattern.test(lines[i])) {
      lines[i] = newLine;
      updated = true;
      console.green(`✓ Đã cập nhật ${provider.description}`);
      break;
    }
  }

  if (!updated) {
    // Nếu không tìm thấy, thêm vào cuối file
    console.orange(`⚠ Không tìm thấy dòng ${provider.envVar} trong file .env, đang thêm vào cuối file...`);
    lines.push('');
    lines.push(`# ${provider.description}`);
    lines.push(newLine);
    updated = true;
  }

  return lines.join('\n');
}

/**
 * Hiển thị danh sách providers
 */
function showProviders() {
  console.purple('\n--------------------------');
  console.purple('Danh sách API Key Providers:');
  console.purple('--------------------------');
  Object.keys(API_KEY_PROVIDERS).forEach((key, index) => {
    const provider = API_KEY_PROVIDERS[key];
    console.cyan(`${index + 1}. ${key.padEnd(15)} - ${provider.description}`);
  });
  console.purple('--------------------------\n');
}

/**
 * Lấy provider từ user input
 */
function getProviderFromInput(input) {
  const lowerInput = input.toLowerCase().trim();

  // Kiểm tra nếu là số
  const providersList = Object.keys(API_KEY_PROVIDERS);
  const index = parseInt(lowerInput) - 1;
  if (!isNaN(index) && index >= 0 && index < providersList.length) {
    return providersList[index];
  }

  // Kiểm tra nếu là tên provider
  if (API_KEY_PROVIDERS[lowerInput]) {
    return lowerInput;
  }

  // Kiểm tra partial match
  const matched = providersList.find((key) => key.includes(lowerInput) || lowerInput.includes(key));
  if (matched) {
    return matched;
  }

  return null;
}

/**
 * Main function
 */
(async () => {
  console.purple('--------------------------');
  console.purple('Thêm API Key vào LibreChat');
  console.purple('--------------------------');

  // Xác định đường dẫn file .env
  // Nếu chạy từ Docker container, file .env ở /app/.env
  // Nếu chạy từ host, file .env ở thư mục gốc dự án
  const isDocker = process.env.NODE_ENV === 'production' || fs.existsSync('/app/.env');
  const envPath = isDocker 
    ? '/app/.env' 
    : path.resolve(__dirname, '..', '.env');

  // Parse command line arguments
  const args = process.argv.slice(2);
  let providerKey = null;
  let apiKey = null;
  let interactive = true;

  if (args.length > 0) {
    providerKey = args[0];
    if (args.length > 1) {
      apiKey = args[1];
      interactive = false;
    }
  }

  // Đọc file .env
  let envContent = readEnvFile(envPath);

  // Interactive mode
  if (interactive) {
    showProviders();

    if (!providerKey) {
      const providerInput = await askQuestion(
        'Chọn provider (nhập số hoặc tên, ví dụ: 1 hoặc openai):',
      );
      providerKey = getProviderFromInput(providerInput);

      if (!providerKey) {
        console.red(`Error: Provider "${providerInput}" không hợp lệ!`);
        silentExit(1);
      }
    }

    const provider = API_KEY_PROVIDERS[providerKey];
    console.cyan(`\nBạn đã chọn: ${provider.description}`);

    if (!apiKey) {
      apiKey = await askQuestion('Nhập API Key (để trống để hủy):');
      if (!apiKey || apiKey.trim() === '') {
        console.orange('Đã hủy thao tác.');
        silentExit(0);
      }
    }
  } else {
    // Non-interactive mode từ command line
    providerKey = getProviderFromInput(providerKey);
    if (!providerKey) {
      console.red(`Error: Provider "${args[0]}" không hợp lệ!`);
      console.orange('Usage: npm run add-api-key <provider> <api_key>');
      console.orange('Ví dụ: npm run add-api-key openai sk-...');
      silentExit(1);
    }
  }

  // Cập nhật API key
  const updatedContent = updateApiKey(envContent, providerKey, apiKey.trim());

  // Xác nhận trước khi ghi
  if (interactive) {
    const confirm = await askQuestion(
      `\nBạn có chắc chắn muốn thêm API key cho ${API_KEY_PROVIDERS[providerKey].description}? (y/n):`,
    );
    if (confirm.toLowerCase() !== 'y' && confirm.toLowerCase() !== 'yes') {
      console.orange('Đã hủy thao tác.');
      silentExit(0);
    }
  }

  // Ghi file .env
  writeEnvFile(envPath, updatedContent);

  console.green('\n✓ Hoàn thành!');
  console.orange(
    '\n⚠ Lưu ý: Bạn cần khởi động lại container để áp dụng thay đổi:',
  );
  console.cyan('   docker-compose restart api');
  console.orange('\nHoặc khởi động lại toàn bộ:');
  console.cyan('   docker-compose restart');

  silentExit(0);
})();

process.on('uncaughtException', (err) => {
  console.error('Có lỗi xảy ra:');
  console.error(err);
  process.exit(1);
});

