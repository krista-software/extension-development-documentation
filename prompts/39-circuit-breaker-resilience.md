# Prompt 39: Circuit Breaker and Resilience Patterns

## Purpose

Implement resilience patterns for extensions that call unreliable external services. Covers circuit breaker (per-invoker/per-tool), graceful degradation, and retry with backoff+jitter.

## Prerequisites

- Existing extension with external API calls
- Understanding of the failure modes of the target API

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Outlook` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.outlook` |

---

## Prompt

```
I need you to implement resilience patterns for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Circuit Breaker

```java
package {{PACKAGE_NAME}}.impl.resilience;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class CircuitBreaker {
    public enum State { CLOSED, OPEN, HALF_OPEN }

    private final int failureThreshold;
    private final long recoveryTimeoutMs;
    private final AtomicInteger failureCount = new AtomicInteger(0);
    private final AtomicReference<State> state = new AtomicReference<>(State.CLOSED);
    private volatile long lastFailureTime = 0;

    public CircuitBreaker(int failureThreshold, long recoveryTimeoutMs) {
        this.failureThreshold = failureThreshold;
        this.recoveryTimeoutMs = recoveryTimeoutMs;
    }

    public static CircuitBreaker withDefaults() {
        return new CircuitBreaker(5, 30_000); // 5 failures, 30s recovery
    }

    public boolean isCallPermitted() {
        State current = state.get();
        if (current == State.CLOSED) return true;
        if (current == State.OPEN) {
            if (System.currentTimeMillis() - lastFailureTime > recoveryTimeoutMs) {
                state.compareAndSet(State.OPEN, State.HALF_OPEN);
                return true; // Allow one test call
            }
            return false;
        }
        return true; // HALF_OPEN allows one call
    }

    public void recordSuccess() {
        failureCount.set(0);
        state.set(State.CLOSED);
    }

    public void recordFailure() {
        lastFailureTime = System.currentTimeMillis();
        if (failureCount.incrementAndGet() >= failureThreshold) {
            state.set(State.OPEN);
        }
    }

    public State getState() { return state.get(); }
}
```

## 2. Per-Invoker Circuit Breaker Registry

```java
package {{PACKAGE_NAME}}.impl.resilience;

import java.util.concurrent.ConcurrentHashMap;

public class CircuitBreakerRegistry {
    private static final ConcurrentHashMap<String, CircuitBreaker> breakers =
        new ConcurrentHashMap<>();

    public static CircuitBreaker getOrCreate(String key) {
        return breakers.computeIfAbsent(key, k -> CircuitBreaker.withDefaults());
    }

    public static void remove(String key) {
        breakers.remove(key);
    }

    public static void clear() {
        breakers.clear();
    }
}
```

## 3. Resilient Operation Executor

```java
package {{PACKAGE_NAME}}.impl.resilience;

import java.util.concurrent.ThreadLocalRandom;

public class ResilientExecutor {

    public static <T> T execute(String operationKey, Operation<T> operation,
            FallbackProvider<T> fallback) throws Exception {

        CircuitBreaker breaker = CircuitBreakerRegistry.getOrCreate(operationKey);

        if (!breaker.isCallPermitted()) {
            if (fallback != null) {
                return fallback.provide("Circuit open for: " + operationKey);
            }
            throw new CircuitOpenException("Service unavailable: " + operationKey);
        }

        try {
            T result = operation.execute();
            breaker.recordSuccess();
            return result;
        } catch (Exception e) {
            breaker.recordFailure();
            if (isRetryable(e) && fallback != null) {
                return fallback.provide(e.getMessage());
            }
            throw e;
        }
    }

    private static boolean isRetryable(Exception e) {
        String msg = e.getMessage();
        if (msg == null) return false;
        return msg.contains("timeout") || msg.contains("503") || msg.contains("429")
            || msg.contains("Connection refused");
    }

    @FunctionalInterface
    public interface Operation<T> {
        T execute() throws Exception;
    }

    @FunctionalInterface
    public interface FallbackProvider<T> {
        T provide(String reason);
    }
}
```

## 4. Retry with Exponential Backoff and Jitter

```java
package {{PACKAGE_NAME}}.impl.resilience;

import java.util.concurrent.ThreadLocalRandom;

public class RetryExecutor {
    private final int maxAttempts;
    private final long baseDelayMs;
    private final long maxDelayMs;

    public RetryExecutor(int maxAttempts, long baseDelayMs, long maxDelayMs) {
        this.maxAttempts = maxAttempts;
        this.baseDelayMs = baseDelayMs;
        this.maxDelayMs = maxDelayMs;
    }

    public static RetryExecutor withDefaults() {
        return new RetryExecutor(3, 1000, 30_000);
    }

    public <T> T execute(ResilientExecutor.Operation<T> operation) throws Exception {
        Exception lastException = null;

        for (int attempt = 0; attempt < maxAttempts; attempt++) {
            try {
                return operation.execute();
            } catch (Exception e) {
                lastException = e;
                if (!isRetryable(e) || attempt == maxAttempts - 1) break;

                long delay = calculateDelay(attempt);
                Thread.sleep(delay);
            }
        }
        throw lastException;
    }

    private long calculateDelay(int attempt) {
        long exponential = baseDelayMs * (1L << attempt);
        long capped = Math.min(exponential, maxDelayMs);
        // Add jitter: ±50% (equal jitter strategy)
        long halfCapped = capped / 2;
        return halfCapped + ThreadLocalRandom.current().nextLong(halfCapped + 1);
    }

    private boolean isRetryable(Exception e) {
        String msg = e.getMessage();
        return msg != null && (msg.contains("timeout") || msg.contains("503")
            || msg.contains("429") || msg.contains("Connection"));
    }
}
```

## 5. Graceful Degradation in Catalog Requests

```java
@CatalogRequest(...)
public ExtensionResponse fetchData(...) {
    long startTime = System.currentTimeMillis();
    try {
        Map<String, Object> result = ResilientExecutor.execute(
            "fetchData_" + invokerId,
            () -> service.fetchFullData(params),
            reason -> {
                // Fallback: return cached/partial data
                LOGGER.warn("Using fallback for fetchData: {}", reason);
                Map<String, Object> partial = new HashMap<>();
                partial.put("warning", "Partial results — service temporarily unavailable");
                partial.put("data", cachedDataStore.getLastKnown());
                return partial;
            }
        );

        telemetryHelper.recordSuccess("fetchData", startTime, Map.of());
        return ExtensionResponseFactory.create(Map.of("Result", result));

    } catch (MustAuthorizeException e) {
        throw e;
    } catch (CircuitOpenException e) {
        telemetryHelper.recordError("fetchData", startTime, e, Map.of());
        return ExtensionResponseFactory.create(
            "Service temporarily unavailable. Please try again shortly.",
            ExtensionResponse.Error.ExceptionType.UNAVAILABILITY_ERROR,
            null, null, null);
    } catch (Exception e) {
        telemetryHelper.recordError("fetchData", startTime, e, Map.of());
        return ExtensionResponseFactory.create(e, "Failed to fetch data", SYSTEM_ERROR);
    }
}
```

## Best Practices

1. **Isolate circuit breakers per invoker or tool** — one failing invoker shouldn't block others
2. **Use fallbacks for non-critical data** — return cached or partial results
3. **Always rethrow MustAuthorizeException** — it's not a circuit breaker concern
4. **Add jitter to backoff** — prevents thundering herd on recovery
5. **Log circuit state transitions** — critical for debugging availability issues
6. **Clean up on INVOKER_REMOVED** — remove circuit breaker state for deleted invokers
7. **Cap retry attempts** — 3 attempts is usually sufficient; fail fast with actionable message

## Related Prompts

- [Prompt 17: Retry and Idempotency](17-add-retry-idempotency.md) — basic retry patterns
- [Prompt 16: Error Handling](16-implement-error-handling.md) — error categorization
- [Prompt 15: Lifecycle Hooks](15-implement-lifecycle-hooks.md) — cleanup on unload/remove
```
