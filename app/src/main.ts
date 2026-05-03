import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';
import { DevLogger } from './app/core/services/dev-logger';

const logger = new DevLogger();

bootstrapApplication(App, appConfig).catch((err) => logger.error('Bootstrap error:', err));
