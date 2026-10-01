const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const apiDelayMs = String.fromEnvironment('API_DELAY');

const apiFailCode = String.fromEnvironment('API_FAIL');

const apiUsername = String.fromEnvironment('API_USERNAME', defaultValue: 'admin');
const apiPassword = String.fromEnvironment('API_PASSWORD', defaultValue: 'admin123');
