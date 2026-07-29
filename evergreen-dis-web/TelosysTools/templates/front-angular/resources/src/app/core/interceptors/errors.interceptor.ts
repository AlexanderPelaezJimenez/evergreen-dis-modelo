import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';

export const errorsInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError( (err: HttpErrorResponse) =>  {
      let errorMessage = 'An unknown error occurred';
      
      if (err.error instanceof ErrorEvent) {
        // Client-side error
        errorMessage = `Client Error: ${err.error.message}`;
      } else {
        // Server-side error
        switch (err.status) {
          case 400:
            errorMessage = 'Bad Request: Invalid data provided';
            break;
          case 401:
            errorMessage = 'Unauthorized: Authentication required';
            break;
          case 403:
            errorMessage = 'Forbidden: Access denied';
            break;
          case 404:
            errorMessage = 'Not Found: Driver not found';
            break;
          case 409:
            errorMessage = 'Conflict: Driver already exists';
            break;
          case 500:
            errorMessage = 'Internal Server Error: Please try again later';
            break;
          default:
            errorMessage = `Server Error: ${err.status} - ${err.message}`;
        }
      }
  
      console.error('Error:', errorMessage, err);
      return throwError(() => new Error(errorMessage));
    })
  );
};
