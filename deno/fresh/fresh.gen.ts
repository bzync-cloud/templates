import * as $_404 from "./routes/_404.tsx";
import * as $health from "./routes/health.ts";
import * as $index from "./routes/index.tsx";

const manifest = {
  routes: {
    "./routes/_404.tsx": $_404,
    "./routes/health.ts": $health,
    "./routes/index.tsx": $index,
  },
  islands: {},
  baseUrl: import.meta.url,
};

export default manifest;
