import {Injectable, Injector} from '@angular/core';
import {HttpEvent, HttpHandler, HttpInterceptor, HttpRequest} from '@angular/common/http';
import {Observable, throwError} from 'rxjs';
import {catchError} from 'rxjs/operators';
import {AuthenticationService} from '../authentication.service';
import {NavigationService} from '../../navigation.service';
import {ErrorCodes} from '../../../../../common/entities/Error';


@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  /**
   * 不能直接构造注入 AuthenticationService：
   * AuthenticationService -> NetworkService -> HttpClient -> 拦截器链 -> ErrorInterceptor
   * 构成循环依赖。而 AuthenticationService 的构造函数里就会发出全站第一个请求（恢复会话），
   * 此时它自己还没构造完，Angular 抛 NG0200，请求根本发不出去，
   * 之后所有请求都走不通（表现为点了登录没反应）。
   * 所以只注入 Injector，真正要处理错误时再把服务取出来。
   */
  constructor(private injector: Injector) {
  }

  intercept(
    request: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError((err) => {
        if (err.status === 401) {
          // auto logout if 401 response returned from server
          this.injector.get(AuthenticationService).logout();
        }
        if (err.status === 500 && err.error.error.code === ErrorCodes.INTERNAL) {
          // Unknown server error
          this.injector.get(NavigationService).toError();
        }

        const error = err.error.error || err.error.message || err.statusText;
        return throwError(error);
      })
    );
  }
}
