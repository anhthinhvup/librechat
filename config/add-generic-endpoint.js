const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const { askQuestion, silentExit } = require('./helpers');

/**
 * Đọc file librechat.yaml
 */
function readYamlFile(yamlPath) {
  try {
    if (!fs.existsSync(yamlPath)) {
      // Nếu file không tồn tại, tạo file mới
      return {
        version: '1.3.0',
        endpoints: {
          custom: [],
        },
      };
    }
    const content = fs.readFileSync(yamlPath, 'utf8');
    return yaml.load(content) || { endpoints: { custom: [] } };
  } catch (error) {
    console.red(`Error reading librechat.yaml: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Ghi file librechat.yaml
 */
function writeYamlFile(yamlPath, data) {
  try {
    const yamlContent = yaml.dump(data, {
      indent: 2,
      lineWidth: -1,
      noRefs: true,
    });
    fs.writeFileSync(yamlPath, yamlContent, 'utf8');
    console.green('✓ File librechat.yaml đã được cập nhật thành công!');
  } catch (error) {
    console.red(`Error writing librechat.yaml: ${error.message}`);
    silentExit(1);
  }
}

/**
 * Main function
 */
(async () => {
  console.purple('--------------------------');
  console.purple('Thêm Generic Custom Endpoint (User-Provided)');
  console.purple('--------------------------');
  console.cyan('\nEndpoint này cho phép người dùng nhập API Key và Base URL trực tiếp từ giao diện web!');
  console.log('');

  // Xác định đường dẫn file
  const isDocker = process.env.NODE_ENV === 'production' || fs.existsSync('/app/.env');
  const yamlPath = isDocker
    ? '/app/librechat.yaml'
    : path.resolve(__dirname, '..', 'librechat.yaml');

  // Parse command line arguments
  const args = process.argv.slice(2);
  let endpointName = null;
  let interactive = true;

  if (args.length >= 1) {
    endpointName = args[0];
    interactive = false;
  }

  // Đọc file YAML
  let config = readYamlFile(yamlPath);

  // Đảm bảo cấu trúc endpoints.custom tồn tại
  if (!config.endpoints) {
    config.endpoints = {};
  }
  if (!config.endpoints.custom) {
    config.endpoints.custom = [];
  }

  // Interactive mode
  if (interactive) {
    console.cyan('\nVí dụ tên endpoint:');
    console.gray('  - myapi');
    console.gray('  - langhit');
    console.gray('  - custom');
    console.gray('  - myprovider');
    console.log('');

    if (!endpointName) {
      endpointName = await askQuestion('Tên endpoint (ví dụ: myapi):');
    }
  }

  if (!endpointName || endpointName.trim() === '') {
    console.red('Error: Tên endpoint không được để trống!');
    silentExit(1);
  }

  endpointName = endpointName.trim();

  // Kiểm tra endpoint đã tồn tại chưa
  const existingIndex = config.endpoints.custom.findIndex(
    (ep) => ep.name && ep.name.toLowerCase() === endpointName.toLowerCase(),
  );

  // Tạo endpoint config với user_provided
  const endpointConfig = {
    name: endpointName,
    apiKey: 'user_provided', // Cho phép user nhập từ UI
    baseURL: 'user_provided', // Cho phép user nhập từ UI
    models: {
      default: ['gpt-3.5-turbo', 'gpt-4'], // Mặc định, user có thể thay đổi
      fetch: true, // Tự động lấy danh sách models từ API (nếu được hỗ trợ)
    },
    titleConvo: true,
    titleModel: 'gpt-3.5-turbo',
    modelDisplayLabel: endpointName.charAt(0).toUpperCase() + endpointName.slice(1),
  };

  if (existingIndex >= 0) {
    // Cập nhật endpoint hiện có
    console.orange(`⚠ Endpoint "${endpointName}" đã tồn tại. Đang cập nhật...`);
    config.endpoints.custom[existingIndex] = endpointConfig;
  } else {
    // Thêm endpoint mới
    config.endpoints.custom.push(endpointConfig);
  }

  // Xác nhận trước khi ghi
  if (interactive) {
    console.cyan('\nCấu hình endpoint:');
    console.white(`  Tên: ${endpointName}`);
    console.white(`  API Key: user_provided (người dùng nhập từ UI)`);
    console.white(`  Base URL: user_provided (người dùng nhập từ UI)`);
    console.white(`  Models: Tự động fetch từ API`);
    console.cyan('\n⚠ Lưu ý: Người dùng sẽ cần nhập API Key và Base URL từ giao diện web khi sử dụng.');
    const confirm = await askQuestion('\nBạn có chắc chắn muốn thêm endpoint này? (y/n):');
    if (confirm.toLowerCase() !== 'y' && confirm.toLowerCase() !== 'yes') {
      console.orange('Đã hủy thao tác.');
      silentExit(0);
    }
  }

  // Ghi file YAML
  writeYamlFile(yamlPath, config);

  console.green('\n✓ Hoàn thành!');
  console.orange('\n⚠ Lưu ý:');
  console.cyan('   1. Bạn cần khởi động lại container để áp dụng thay đổi:');
  console.white('      docker-compose restart api');
  console.cyan('   2. Sau khi khởi động lại, người dùng có thể:');
  console.white('      - Đăng nhập vào LibreChat');
  console.white('      - Chọn endpoint "' + endpointName + '" trong danh sách providers');
  console.white('      - Click vào biểu tượng 🔑 để nhập API Key và Base URL');
  console.white('      - Nhập token và URL API của bạn');
  console.white('      - Sử dụng ngay!');
  console.cyan('   3. API Key và Base URL sẽ được lưu an toàn và mã hóa trong database');

  silentExit(0);
})();

process.on('uncaughtException', (err) => {
  console.error('Có lỗi xảy ra:');
  console.error(err);
  process.exit(1);
});

