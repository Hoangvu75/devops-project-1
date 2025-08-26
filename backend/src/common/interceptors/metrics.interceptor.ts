import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, catchError, tap } from 'rxjs';
import { MetricsService } from '../../metrics/metrics.service';
import type { Request, Response } from 'express';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const http = context.switchToHttp();
    const request = http.getRequest<Request>();
    const response = http.getResponse<Response>();

    const method = request.method;
    const route = (request as any).route?.path ?? request.path ?? request.url;

    const endTimer = this.metricsService.startHttpRequestTimer(method, route);

    return next.handle().pipe(
      tap(() => {
        const statusCode = response.statusCode ?? 200;
        endTimer({ status_code: String(statusCode) });
        this.metricsService.incrementHttpRequests(method, route, statusCode);
      }),
      catchError((err) => {
        const statusCode = err?.status ?? 500;
        endTimer({ status_code: String(statusCode) });
        this.metricsService.incrementHttpRequests(method, route, statusCode);
        throw err;
      }),
    );
  }
} 