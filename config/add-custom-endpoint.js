const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const { askQuestion, silentExit } = require('./helpers');

// Một số custom endpoint phổ biến
const COMMON_ENDPOINTS = {
  langhit: {
    name: 'Langhit',
    baseURL: 'https://api.langhit.com/v1',
    description: 'Langhit API (proxy service)',
    models: {
      default: ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo'],
      fetch: true,
    },
  },
  openrouter: {
    name: 'OpenRouter',
    baseURL: 'https://openrouter.ai/api/v1',
    description: 'OpenRouter API',
    models: {
      default: ['meta-llama/llama-3-70b-instruct'],
      fetch: true,
    },
  },
  groq: {
    name: 'Groq',
    baseURL: 'https://api.groq.com/openai/v1/',
    description: 'Groq API',
    models: {
      default: ['llama3-70b-8192', 'llama3-8b-8192', 'mixtral-8x7b-32768'],
      fetch: false,
    },
  },
  mistral: {
    name: 'Mistral',
    baseURL: 'https://api.mistral.ai/v1',
    description: 'Mistral AI API',
    models: {
      default: ['mistral-tiny', 'mistral-small', 'mistral-medium'],
      fetch: true,
    },
  },
};

/**
 * Đọc file librechat.yaml
 */
function readYamlFile(yamlPath) {
  try {
    if (!fs.existsSync(yamlPath)) {
      // Tạo file mới nếu chưa tồn tại
      const defaultConfig = {
        version: '1.2.1',
        cache: true,
        endpoints: {
          custom: [],
        },
      };
      return defaultConfig;
    }
    const fileContents = fs.readFileSync(yamlPath, 'utf8');
    return yaml.load(fileContents) || {};
  } catch (error) {
    console.red(`Error reading librechat.yaml: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Ghi file librechat.yaml
 */
function writeYamlFile(yamlPath, config) {
  try {
    const yamlStr = yaml.dump(config, {
      indent: 2,
      lineWidth: -1,
      noRefs: true,
      quotingType: '"',
    });
    fs.writeFileSync(yamlPath, yamlStr, 'utf8');
    console.green('✓ File librechat.yaml đã được cập nhật thành công!');
  } catch (error) {
    console.red(`Error writing librechat.yaml: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Thêm custom endpoint vào config
 */
function addCustomEndpoint(config, endpointConfig) {
  // Đảm bảo có phần endpoints
  if (!config.endpoints) {
    config.endpoints = {};
  }

  // Đảm bảo có phần custom
  if (!config.endpoints.custom) {
    config.endpoints.custom = [];
  }

  // Kiểm tra xem endpoint đã tồn tại chưa
  const existingIndex = config.endpoints.custom.findIndex(
    (ep) => ep.name === endpointConfig.name,
  );

  if (existingIndex >= 0) {
    console.orange(`⚠ Endpoint "${endpointConfig.name}" đã tồn tại. Đang cập nhật...`);
    config.endpoints.custom[existingIndex] = endpointConfig;
  } else {
    config.endpoints.custom.push(endpointConfig);
  }

  return config;
}

/**
 * Hiển thị danh sách endpoints phổ biến
 */
function showCommonEndpoints() {
  console.purple('\n--------------------------');
  console.purple('Danh sách Custom Endpoints phổ biến:');
  console.purple('--------------------------');
  Object.keys(COMMON_ENDPOINTS).forEach((key, index) => {
    const endpoint = COMMON_ENDPOINTS[key];
    console.cyan(`${index + 1}. ${key.padEnd(15)} - ${endpoint.description}`);
    console.gray(`   Base URL: ${endpoint.baseURL}`);
  });
  console.purple('--------------------------\n');
}

/**
 * Main function
 */
(async () => {
  console.purple('--------------------------');
  console.purple('Thêm Custom Endpoint vào LibreChat');
  console.purple('--------------------------');

  // Xác định đường dẫn file
  const isDocker = process.env.NODE_ENV === 'production' || fs.existsSync('/app/librechat.yaml');
  const yamlPath = isDocker ? '/app/librechat.yaml' : path.resolve(__dirname, '..', 'librechat.yaml');
  const envPath = isDocker ? '/app/.env' : path.resolve(__dirname, '..', '.env');

  // Parse command line arguments
  const args = process.argv.slice(2);
  let endpointName = null;
  let apiKey = null;
  let baseURL = null;
  let useCommon = null;
  let interactive = true;

  if (args.length > 0) {
    interactive = false;
    endpointName = args[0];
    if (args.length > 1) {
    apiKey = args[1];
    }
    if (args.length > 2) {
    baseURL = args[2];
    }
  }

  // Đọc file config
  let config = readYamlFile(yamlPath);

  if (interactive) {
    showCommonEndpoints();

    // Chọn endpoint phổ biến hoặc tùy chỉnh
    const choice = await askQuestion(
      'Chọn endpoint phổ biến (nhập số) hoặc "custom" để tùy chỉnh:',
    );

    if (choice && !isNaN(parseInt(choice))) {
      const commonKeys = Object.keys(COMMON_ENDPOINTS);
      const index = parseInt(choice) - 1;
      if (index >= 0 && index < commonKeys.length) {
        useCommon = commonKeys[index];
        const commonEndpoint = COMMON_ENDPOINTS[useCommon];
        endpointName = commonEndpoint.name.toLowerCase();
        baseURL = commonEndpoint.baseURL;
        console.cyan(`\nBạn đã chọn: ${commonEndpoint.description}`);
      }
    }

    if (!endpointName) {
      endpointName = await askQuestion('Tên endpoint (ví dụ: langhit, myapi):');
      if (!endpointName || endpointName.trim() === '') {
        console.orange('Đã hủy thao tác.');
        silentExit(0);
      }
    }

    if (!baseURL) {
      baseURL = await askQuestion(
        'Base URL (ví dụ: https://api.langhit.com/v1):',
      );
      if (!baseURL || baseURL.trim() === '') {
        console.orange('Đã hủy thao tác.');
        silentExit(0);
      }
    }

    if (!apiKey) {
      const apiKeyChoice = await askQuestion(
        'API Key:\n1. Nhập trực tiếp\n2. Sử dụng từ biến môi trường (ví dụ: ${LANGHIT_API_KEY})\n3. Để người dùng nhập khi sử dụng (user_provided)\nChọn (1/2/3, mặc định: 1):',
      );

      if (apiKeyChoice === '2') {
        const envVarName = await askQuestion(
          'Tên biến môi trường (ví dụ: LANGHIT_API_KEY):',
        );
        apiKey = `\${${envVarName}}`;
        console.cyan(
          `\nSẽ sử dụng biến môi trường: ${envVarName}\nBạn cần thêm ${envVarName}=your_api_key vào file .env`,
        );
      } else if (apiKeyChoice === '3') {
        apiKey = 'user_provided';
        console.cyan('\nNgười dùng sẽ nhập API key khi sử dụng endpoint này.');
      } else {
        apiKey = await askQuestion('Nhập API Key:');
        if (!apiKey || apiKey.trim() === '') {
          console.orange('Đã hủy thao tác.');
          silentExit(0);
        }
      }
    }
  } else {
    // Non-interactive mode
    if (!baseURL) {
      // Kiểm tra xem có phải endpoint phổ biến không
      if (COMMON_ENDPOINTS[endpointName.toLowerCase()]) {
        const commonEndpoint = COMMON_ENDPOINTS[endpointName.toLowerCase()];
        baseURL = commonEndpoint.baseURL;
        endpointName = commonEndpoint.name;
      } else {
        console.red('Error: Thiếu baseURL. Sử dụng: node config/add-custom-endpoint.js <name> <apiKey> <baseURL>');
        silentExit(1);
      }
    }

    if (!apiKey) {
      apiKey = 'user_provided';
      console.orange('⚠ Không có API key, sẽ để người dùng nhập khi sử dụng.');
    }
  }

  // Tạo endpoint config
  const endpointConfig = {
    name: endpointName.trim(),
    apiKey: apiKey.trim(),
    baseURL: baseURL.trim(),
    models: useCommon
      ? COMMON_ENDPOINTS[useCommon].models
      : {
          default: ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo'],
          fetch: true,
    },
    titleConvo: true,
    titleModel: 'gpt-3.5-turbo',
    modelDisplayLabel: endpointName.trim().charAt(0).toUpperCase() + endpointName.trim().slice(1),
  };

  // Nếu sử dụng biến môi trường, kiểm tra và thêm vào .env nếu cần
  if (apiKey.startsWith('${') && apiKey.endsWith('}')) {
    const envVarName = apiKey.slice(2, -1);
    const envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
    
    if (!envContent.includes(`${envVarName}=`)) {
      const addEnv = await askQuestion(
        `\nBiến môi trường ${envVarName} chưa có trong .env. Bạn có muốn thêm không? (y/n):`,
      );
      if (addEnv.toLowerCase() === 'y' || addEnv.toLowerCase() === 'yes') {
        const envKeyValue = await askQuestion(`Nhập giá trị cho ${envVarName}:`);
        fs.appendFileSync(envPath, `\n# ${endpointConfig.name} API Key\n${envVarName}=${envKeyValue}\n`, 'utf8');
        console.green(`✓ Đã thêm ${envVarName} vào file .env`);
      }
    }
  }

  // Xác nhận
  if (interactive) {
    console.cyan('\n--- Thông tin endpoint sẽ được thêm ---');
    console.white(`Tên: ${endpointConfig.name}`);
    console.white(`Base URL: ${endpointConfig.baseURL}`);
    console.white(`API Key: ${apiKey.startsWith('${') ? apiKey : '***' + apiKey.slice(-4)}`);
    console.white(`Models: ${endpointConfig.models.default.join(', ')}`);
    console.cyan('----------------------------------------\n');

    const confirm = await askQuestion('Bạn có chắc chắn muốn thêm endpoint này? (y/n):');
    if (confirm.toLowerCase() !== 'y' && confirm.toLowerCase() !== 'yes') {
      console.orange('Đã hủy thao tác.');
      silentExit(0);
    }
  }

  // Thêm endpoint vào config
  config = addCustomEndpoint(config, endpointConfig);

  // Ghi file
  writeYamlFile(yamlPath, config);

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
