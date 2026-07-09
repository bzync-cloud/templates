import { Handlers } from "$fresh/server.ts";

export const handler: Handlers = {
  GET() {
    return Response.json({ status: "ok" });
  },
};
