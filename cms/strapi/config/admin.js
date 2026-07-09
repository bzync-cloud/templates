module.exports = ({ env }) => ({
  auth: {
    secret: env("ADMIN_JWT_SECRET", "starter-admin-jwt-secret"),
  },
  apiToken: {
    salt: env("API_TOKEN_SALT", "starter-api-token-salt"),
  },
  transfer: {
    token: {
      salt: env("TRANSFER_TOKEN_SALT", "starter-transfer-token-salt"),
    },
  },
});
