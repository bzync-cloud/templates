const fastify = require('fastify')({ logger: true });

const port = process.env.PORT || 3000;

fastify.get('/health', async () => ({ status: 'ok' }));
fastify.get('/', async () => ({ message: 'Welcome to the API' }));

fastify.listen({ port, host: '0.0.0.0' }, (err) => {
  if (err) { fastify.log.error(err); process.exit(1); }
});
