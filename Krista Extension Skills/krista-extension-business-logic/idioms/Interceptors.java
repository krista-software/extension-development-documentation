// IDIOM — OkHttp interceptors: header auth, transient retry with jitter, rate-limit fail-fast.
// Adapt names. Prefer resilience4j Retry/CircuitBreaker decorators over the hand-rolled retry when you can.
package {{PACKAGE}}.integration;

import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

// ============================================================================
// Auth interceptor — stateless; rewrites EVERY request with the required headers.
// (Header-based auth, e.g. autotask: UserName/Secret/ApiIntegrationCode. For Bearer, do it inline in the client.)
// ============================================================================
class AuthenticationInterceptor implements Interceptor {
    private static final Logger LOG = LoggerFactory.getLogger(AuthenticationInterceptor.class);
    private final {{ATTRS_CLASS}} cfg;
    AuthenticationInterceptor({{ATTRS_CLASS}} cfg) { this.cfg = cfg; }

    @Override public Response intercept(Chain chain) throws IOException {
        Request req = chain.request().newBuilder()
                .header("UserName", cfg.getUsername())
                .header("Secret", cfg.getSecret())
                .header("ApiIntegrationCode", cfg.getApiIntegrationCode())
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .build();
        LOG.debug("Request -> {} (auth headers set)", req.url());  // URL only — never the secret
        return chain.proceed(req);
    }
}

// ============================================================================
// Retry interceptor — retry ONLY transient failures; exponential backoff + jitter.
// ============================================================================
class RetryInterceptor implements Interceptor {
    private static final Logger LOG = LoggerFactory.getLogger(RetryInterceptor.class);
    private final int maxAttempts;
    private final long baseDelayMillis;
    RetryInterceptor({{ATTRS_CLASS}} cfg) { this.maxAttempts = cfg.getMaxRetryAttempts(); this.baseDelayMillis = cfg.getRetryDelayMillis(); }

    @Override public Response intercept(Chain chain) throws IOException {
        Request request = chain.request();
        Response response = null;
        IOException last = null;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                if (response != null) response.close();          // don't leak connections
                response = chain.proceed(request);
                if (shouldRetry(response.code()) && attempt < maxAttempts) {
                    LOG.warn("HTTP {} — retry {}/{}", response.code(), attempt, maxAttempts);
                    sleep(delay(attempt));
                    continue;
                }
                return response;                                 // success or non-retryable
            } catch (IOException e) {
                last = e;
                if (attempt < maxAttempts) sleep(delay(attempt)); else throw e;
            }
        }
        if (last != null) throw last;
        return response;
    }
    private boolean shouldRetry(int c) { return c == 429 || c == 502 || c == 503 || c == 504; }
    private long delay(int attempt) {
        if (attempt == 1) return 0;
        long base = (long) Math.pow(2, attempt - 2) * baseDelayMillis;
        return base + (long) (Math.random() * base * 0.5);       // 0–50% jitter
    }
    private void sleep(long ms) {
        try { TimeUnit.MILLISECONDS.sleep(ms); }
        catch (InterruptedException e) { Thread.currentThread().interrupt(); }  // restore flag
    }
}

// ============================================================================
// Rate-limit interceptor — snapshot X-RateLimit-* (volatile, thread-safe read); fail fast on 429/exhausted-403.
// ============================================================================
class RateLimitInterceptor implements Interceptor {
    private static final Logger LOG = LoggerFactory.getLogger(RateLimitInterceptor.class);
    private volatile int remaining = -1;
    private volatile long resetEpoch = -1;

    @Override public Response intercept(Chain chain) throws IOException {
        Response response = chain.proceed(chain.request());
        parse(response, "X-RateLimit-Remaining", v -> remaining = Integer.parseInt(v));
        parse(response, "X-RateLimit-Reset", v -> resetEpoch = Long.parseLong(v));
        if (response.code() == 429 || (response.code() == 403 && remaining == 0)) {
            response.close();
            long waitS = Math.max(0, resetEpoch - Instant.now().getEpochSecond());
            throw new IOException("Rate limited. Resets in " + waitS + "s.");
        }
        return response;
    }
    public boolean isRateLimited() { return remaining == 0; }
    private void parse(Response r, String h, java.util.function.Consumer<String> set) {
        String v = r.header(h);
        if (v != null) { try { set.accept(v); } catch (NumberFormatException ignored) {} }
    }
}
