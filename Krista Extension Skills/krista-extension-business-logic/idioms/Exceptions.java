// IDIOM — typed exception hierarchy + status->exception mapping (the "decomposed" variant).
// For the "compact" variant, throw built-in SecurityException/IllegalArgumentException/
// IllegalStateException/IOException directly from the client (see HttpClient.java).
package {{PACKAGE}}.integration.exception;

import java.util.List;

// ---- base ----
public class {{EXT}}Exception extends RuntimeException {
    private final int statusCode;
    private final String errorCode;
    public {{EXT}}Exception(String message, int statusCode, String errorCode) {
        super(message); this.statusCode = statusCode; this.errorCode = errorCode;
    }
    public {{EXT}}Exception(String message, Throwable cause) { super(message, cause); this.statusCode = 0; this.errorCode = "API_ERROR"; }
    public int getStatusCode() { return statusCode; }
    public String getErrorCode() { return errorCode; }
}

// ---- subclasses (one per failure mode; self-enhance messages idempotently) ----
class AuthenticationException extends {{EXT}}Exception {
    AuthenticationException(String m) { super(enhance(m), 401, "AUTHENTICATION_FAILED"); }
    private static String enhance(String m) {
        if (m != null && m.contains("Please")) return m;
        return (m != null ? m : "Authentication failed") + ". Please verify the credentials in the Setup tab and try again.";
    }
}
class PermissionDeniedException extends {{EXT}}Exception { PermissionDeniedException(String m) { super(m, 403, "PERMISSION_DENIED"); } }
class NotFoundException extends {{EXT}}Exception { NotFoundException(String m) { super(m, 404, "NOT_FOUND"); } }
class RateLimitException extends {{EXT}}Exception {
    private final int retryAfterSeconds;
    RateLimitException(String m, int retryAfterSeconds) { super(m, 429, "RATE_LIMIT_EXCEEDED"); this.retryAfterSeconds = retryAfterSeconds; }
    public int getRetryAfterSeconds() { return retryAfterSeconds; }
}
class NetworkException extends {{EXT}}Exception {
    private final boolean retryable;
    NetworkException(String m, int statusCode) { super(m, statusCode, "NETWORK_ERROR"); this.retryable = true; }
    NetworkException(String m, Throwable cause) { super(m, cause); this.retryable = true; }
    public boolean isRetryable() { return retryable; }
}
class ValidationException extends {{EXT}}Exception {
    private final List<String> validationErrors;
    ValidationException(List<String> errors) { super(String.join("; ", errors), 400, "VALIDATION_ERROR"); this.validationErrors = errors; }
    public List<String> getValidationErrors() { return validationErrors; }
}

// ---- the single mapping point (call from the client's execute() on non-2xx) ----
// void handleErrorResponse(int statusCode, String responseBody) {
//     String apiMsg = extractMessage(responseBody);              // vendor 'message'
//     String userMsg = friendlyMessageFor(statusCode, apiMsg);   // actionable constant
//     switch (statusCode) {
//         case 401 -> throw new AuthenticationException(userMsg);
//         case 403 -> throw new PermissionDeniedException(userMsg);
//         case 404 -> throw new NotFoundException(userMsg);
//         case 400 -> throw new ValidationException(extractFieldErrors(responseBody));
//         case 429 -> throw new RateLimitException(userMsg, 60);
//         case 500, 502, 503, 504 -> throw new NetworkException(userMsg, statusCode);
//         default  -> throw new {{EXT}}Exception(userMsg, statusCode, "API_ERROR");
//     }
// }
