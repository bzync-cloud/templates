import { config, list } from "@keystone-6/core";
import { password, text, timestamp } from "@keystone-6/core/fields";

export default config({
  server: {
    host: "0.0.0.0",
    port: Number(process.env.PORT ?? 3000),
  },
  db: {
    provider: "sqlite",
    url: process.env.DATABASE_URL ?? "file:./keystone.db",
  },
  lists: {
    User: list({
      fields: {
        name: text({ validation: { isRequired: true } }),
        email: text({ validation: { isRequired: true }, isIndexed: "unique" }),
        password: password({ validation: { isRequired: true } }),
        createdAt: timestamp({ defaultValue: { kind: "now" } }),
      },
    }),
  },
});
