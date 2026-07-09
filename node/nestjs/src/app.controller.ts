import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  root() {
    return { message: 'Welcome to the API' };
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }
}
