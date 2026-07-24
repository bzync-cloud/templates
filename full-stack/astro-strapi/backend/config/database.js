module.exports = ({ env }) => ({
  connection: {
    client: "postgres",
    connection: {
      host: env("DB_HOST", "127.0.0.1"),
      port: env.int("DB_PORT", 5432),
      database: env("DB_NAME", "strapi"),
      user: env("DB_USER", "strapi"),
      password: env("DB_PASSWORD", "strapi"),
      ssl: env.bool("DATABASE_SSL", false),
    },
    pool: {
      min: env.int("DATABASE_POOL_MIN", 2),
      max: env.int("DATABASE_POOL_MAX", 10),
    },
  },
});
