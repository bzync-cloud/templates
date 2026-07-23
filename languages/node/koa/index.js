const Koa = require('koa');
const Router = require('@koa/router');
const bodyParser = require('koa-bodyparser');

const app = new Koa();
const router = new Router();
const port = process.env.PORT || 3000;

router.get('/health', (ctx) => { ctx.body = { status: 'ok' }; });
router.get('/', (ctx) => { ctx.body = { message: 'Welcome to the API' }; });

app.use(bodyParser());
app.use(router.routes());
app.use(router.allowedMethods());

app.listen(port, () => console.log(`Server running on port ${port}`));
