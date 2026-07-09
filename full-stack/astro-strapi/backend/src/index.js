module.exports = {
  register({ strapi }) {
    strapi.server.routes([
      {
        method: "GET",
        path: "/_health",
        handler: (ctx) => {
          ctx.body = { status: "ok" };
        },
        config: { auth: false },
      },
    ]);
  },
};
