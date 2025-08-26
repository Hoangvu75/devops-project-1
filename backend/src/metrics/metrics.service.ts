import { Injectable, OnModuleInit } from '@nestjs/common';
import { Counter, Histogram, Registry, collectDefaultMetrics } from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry: Registry = new Registry();
  private readonly httpRequestsCounter: Counter<string>;
  private readonly httpRequestDurationSeconds: Histogram<string>;

  constructor() {
    this.httpRequestsCounter = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code'],
      registers: [this.registry],
    });

    this.httpRequestDurationSeconds = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds',
      labelNames: ['method', 'route', 'status_code'],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry],
    });
  }

  onModuleInit(): void {
    collectDefaultMetrics({ register: this.registry });
  }

  startHttpRequestTimer(method: string, route: string): (labels?: Record<string, string>) => number {
    return this.httpRequestDurationSeconds.startTimer({ method, route });
  }

  incrementHttpRequests(method: string, route: string, statusCode: number): void {
    this.httpRequestsCounter.inc({ method, route, status_code: String(statusCode) });
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }
} 