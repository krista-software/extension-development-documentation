# Prompt 17: Add Retry and Idempotency Support

## Purpose

Implement retry logic with exponential backoff and idempotency support for catalog requests. This ensures reliable operation handling even when transient failures occur, while preventing duplicate operations.

## Prerequisites

- Existing extension with catalog requests
- Understanding of which operations are idempotent
- Error handling already implemented

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |

---

## Prompt

```
I need you to implement retry and idempotency support for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Create Retry Configuration

```java
package {{PACKAGE_NAME}}.retry;

import java.time.Duration;

/**
 * Configuration for retry behavior.
 */
public class RetryConfig {

    private final int maxAttempts;
    private final Duration initialDelay;
    private final Duration maxDelay;
    private final double backoffMultiplier;
    private final boolean retryOnTimeout;
    private final boolean retryOnServerError;
    private final boolean retryOnRateLimit;

    private RetryConfig(Builder builder) {
        this.maxAttempts = builder.maxAttempts;
        this.initialDelay = builder.initialDelay;
        this.maxDelay = builder.maxDelay;
        this.backoffMultiplier = builder.backoffMultiplier;
        this.retryOnTimeout = builder.retryOnTimeout;
        this.retryOnServerError = builder.retryOnServerError;
        this.retryOnRateLimit = builder.retryOnRateLimit;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static RetryConfig defaultConfig() {
        return builder()
            .maxAttempts(3)
            .initialDelay(Duration.ofSeconds(1))
            .maxDelay(Duration.ofSeconds(30))
            .backoffMultiplier(2.0)
            .retryOnTimeout(true)
            .retryOnServerError(true)
            .retryOnRateLimit(true)
            .build();
    }

    public int getMaxAttempts() { return maxAttempts; }
    public Duration getInitialDelay() { return initialDelay; }
    public Duration getMaxDelay() { return maxDelay; }
    public double getBackoffMultiplier() { return backoffMultiplier; }
    public boolean isRetryOnTimeout() { return retryOnTimeout; }
    public boolean isRetryOnServerError() { return retryOnServerError; }
    public boolean isRetryOnRateLimit() { return retryOnRateLimit; }

    public static class Builder {
        private int maxAttempts = 3;
        private Duration initialDelay = Duration.ofSeconds(1);
        private Duration maxDelay = Duration.ofSeconds(30);
        private double backoffMultiplier = 2.0;
        private boolean retryOnTimeout = true;
        private boolean retryOnServerError = true;
        private boolean retryOnRateLimit = true;

        public Builder maxAttempts(int maxAttempts) {
            this.maxAttempts = maxAttempts;
            return this;
        }

        public Builder initialDelay(Duration initialDelay) {
            this.initialDelay = initialDelay;
            return this;
        }

        public Builder maxDelay(Duration maxDelay) {
            this.maxDelay = maxDelay;
            return this;
        }

        public Builder backoffMultiplier(double backoffMultiplier) {
            this.backoffMultiplier = backoffMultiplier;
            return this;
        }

        public Builder retryOnTimeout(boolean retryOnTimeout) {
            this.retryOnTimeout = retryOnTimeout;
            return this;
        }

        public Builder retryOnServerError(boolean retryOnServerError) {
            this.retryOnServerError = retryOnServerError;
            return this;
        }

        public Builder retryOnRateLimit(boolean retryOnRateLimit) {
            this.retryOnRateLimit = retryOnRateLimit;
            return this;
        }

        public RetryConfig build() {
            return new RetryConfig(this);
        }
    }
}
```

## 2. Create Retry Executor

```java
package {{PACKAGE_NAME}}.retry;

import {{PACKAGE_NAME}}.error.ExtensionException;
import {{PACKAGE_NAME}}.error.ErrorType;

import java.time.Duration;
import java.util.concurrent.*;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Executes operations with retry logic and exponential backoff.
 */
public class RetryExecutor {

    private static final Logger logger = LoggerFactory.getLogger(RetryExecutor.class);

    private final RetryConfig config;

    public RetryExecutor() {
        this(RetryConfig.defaultConfig());
    }

    public RetryExecutor(RetryConfig config) {
        this.config = config;
    }

    /**
     * Execute an operation with retry logic.
     * 
     * @param operation The operation to execute
     * @param operationName Name for logging
     * @return Result of the operation
     * @throws ExtensionException if all retries fail
     */
    public <T> T execute(Supplier<T> operation, String operationName) {
        int attempt = 0;
        ExtensionException lastException = null;
        
        while (attempt < config.getMaxAttempts()) {
            attempt++;
            
            try {
                logger.debug("Executing {} (attempt {}/{})", 
                    operationName, attempt, config.getMaxAttempts());
                
                T result = operation.get();
                
                if (attempt > 1) {
                    logger.info("{} succeeded on attempt {}", operationName, attempt);
                }
                
                return result;
                
            } catch (ExtensionException e) {
                lastException = e;

                if (!shouldRetry(e, attempt)) {
                    logger.debug("{} failed with non-retryable error: {}",
                        operationName, e.getMessage());
                    throw e;
                }

                if (attempt < config.getMaxAttempts()) {
                    Duration delay = calculateDelay(attempt);
                    logger.warn("{} failed (attempt {}), retrying in {}ms: {}",
                        operationName, attempt, delay.toMillis(), e.getMessage());

                    sleep(delay);
                }

            } catch (Exception e) {
                // Wrap unexpected exceptions
                lastException = ExtensionException.systemError(
                    "Unexpected error: " + e.getMessage(), e, false);
                throw lastException;
            }
        }

        // All retries exhausted
        logger.error("{} failed after {} attempts", operationName, config.getMaxAttempts());
        throw lastException;
    }

    /**
     * Determine if an exception should trigger a retry.
     */
    private boolean shouldRetry(ExtensionException e, int attempt) {
        // Don't retry if we've exhausted attempts
        if (attempt >= config.getMaxAttempts()) {
            return false;
        }

        // Don't retry non-retryable errors
        if (!e.isRetryable()) {
            return false;
        }

        // Check error type specific retry settings
        ErrorType errorType = e.getErrorType();
        String errorCode = e.getErrorCode();

        // Never retry input or authorization errors
        if (errorType == ErrorType.INPUT_ERROR ||
            errorType == ErrorType.AUTHORIZATION_ERROR) {
            return false;
        }

        // Check specific error codes
        if ("TIMEOUT".equals(errorCode) && !config.isRetryOnTimeout()) {
            return false;
        }

        if (errorCode != null && errorCode.startsWith("HTTP_5") &&
            !config.isRetryOnServerError()) {
            return false;
        }

        if ("RATE_LIMITED".equals(errorCode) && !config.isRetryOnRateLimit()) {
            return false;
        }

        return true;
    }

    /**
     * Calculate delay with exponential backoff.
     */
    private Duration calculateDelay(int attempt) {
        double delayMs = config.getInitialDelay().toMillis() *
            Math.pow(config.getBackoffMultiplier(), attempt - 1);

        // Add jitter (±10%)
        double jitter = delayMs * 0.1 * (Math.random() * 2 - 1);
        delayMs += jitter;

        // Cap at max delay
        delayMs = Math.min(delayMs, config.getMaxDelay().toMillis());

        return Duration.ofMillis((long) delayMs);
    }

    private void sleep(Duration duration) {
        try {
            Thread.sleep(duration.toMillis());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw ExtensionException.systemError("Operation interrupted", e, false);
        }
    }
}
```

## 3. Create Idempotency Key Manager

```java
package {{PACKAGE_NAME}}.retry;

import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.*;

/**
 * Manages idempotency keys to prevent duplicate operations.
 */
public class IdempotencyManager {

    // Cache of completed operations: idempotencyKey -> result
    private final Map<String, CachedResult> completedOperations;
    private final long cacheTtlMs;

    public IdempotencyManager() {
        this(TimeUnit.HOURS.toMillis(24)); // 24 hour default TTL
    }

    public IdempotencyManager(long cacheTtlMs) {
        this.cacheTtlMs = cacheTtlMs;
        this.completedOperations = new ConcurrentHashMap<>();

        // Start cleanup thread
        startCleanupThread();
    }

    /**
     * Generate an idempotency key from operation parameters.
     */
    public String generateKey(String operationName, Map<String, Object> params) {
        StringBuilder sb = new StringBuilder();
        sb.append(operationName).append(":");

        // Sort keys for consistent ordering
        params.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .forEach(e -> sb.append(e.getKey()).append("=").append(e.getValue()).append(";"));

        return hash(sb.toString());
    }

    /**
     * Check if operation was already completed.
     *
     * @return Cached result if exists, null otherwise
     */
    public Map<String, Object> getCachedResult(String idempotencyKey) {
        CachedResult cached = completedOperations.get(idempotencyKey);

        if (cached != null && !cached.isExpired()) {
            return cached.getResult();
        }

        return null;
    }

    /**
     * Cache a completed operation result.
     */
    public void cacheResult(String idempotencyKey, Map<String, Object> result) {
        completedOperations.put(idempotencyKey,
            new CachedResult(result, System.currentTimeMillis() + cacheTtlMs));
    }

    /**
     * Check if operation is in progress (for distributed locking).
     */
    public boolean tryAcquireLock(String idempotencyKey) {
        CachedResult existing = completedOperations.putIfAbsent(
            idempotencyKey,
            new CachedResult(null, System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(5))
        );
        return existing == null;
    }

    /**
     * Release lock if operation failed.
     */
    public void releaseLock(String idempotencyKey) {
        CachedResult cached = completedOperations.get(idempotencyKey);
        if (cached != null && cached.getResult() == null) {
            completedOperations.remove(idempotencyKey);
        }
    }

    private String hash(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString().substring(0, 32); // Use first 32 chars
        } catch (Exception e) {
            return input.hashCode() + "";
        }
    }

    private void startCleanupThread() {
        Thread cleanup = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                try {
                    Thread.sleep(TimeUnit.MINUTES.toMillis(5));
                    cleanupExpired();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
        cleanup.setDaemon(true);
        cleanup.setName("IdempotencyCleanup");
        cleanup.start();
    }

    private void cleanupExpired() {
        completedOperations.entrySet().removeIf(e -> e.getValue().isExpired());
    }

    private static class CachedResult {
        private final Map<String, Object> result;
        private final long expiresAt;

        CachedResult(Map<String, Object> result, long expiresAt) {
            this.result = result;
            this.expiresAt = expiresAt;
        }

        Map<String, Object> getResult() { return result; }
        boolean isExpired() { return System.currentTimeMillis() > expiresAt; }
    }
}
```

## 4. Use Retry and Idempotency in Catalog Request

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.retry.*;
import {{PACKAGE_NAME}}.error.*;
import {{PACKAGE_NAME}}.integration.ApiClient;

import java.util.*;

public class RecordsArea {

    private final ApiClient client;
    private final RetryExecutor retryExecutor;
    private final IdempotencyManager idempotencyManager;

    public RecordsArea(ApiClient client) {
        this.client = client;
        this.retryExecutor = new RetryExecutor(
            RetryConfig.builder()
                .maxAttempts(3)
                .initialDelay(Duration.ofSeconds(1))
                .maxDelay(Duration.ofSeconds(30))
                .build()
        );
        this.idempotencyManager = new IdempotencyManager();
    }

    @CatalogRequest(
        name = "Create Record",
        domain = "Records",
        type = CatalogRequest.Type.CHANGE_SYSTEM
    )
    public Map<String, Object> createRecord(Map<String, Object> params) {
        // Generate idempotency key
        String idempotencyKey = idempotencyManager.generateKey("CreateRecord", params);

        // Check for cached result (duplicate request)
        Map<String, Object> cachedResult = idempotencyManager.getCachedResult(idempotencyKey);
        if (cachedResult != null) {
            // Return cached result with indicator
            Map<String, Object> result = new HashMap<>(cachedResult);
            result.put("_cached", true);
            return result;
        }

        // Try to acquire lock
        if (!idempotencyManager.tryAcquireLock(idempotencyKey)) {
            // Another request is in progress
            return ErrorResponseBuilder.buildErrorResponse(
                ExtensionException.logicError("DUPLICATE_REQUEST",
                    "This operation is already in progress")
            );
        }

        try {
            // Execute with retry
            Map<String, Object> result = retryExecutor.execute(
                () -> executeCreateRecord(params),
                "CreateRecord"
            );

            // Cache successful result
            if (Boolean.TRUE.equals(result.get("success"))) {
                idempotencyManager.cacheResult(idempotencyKey, result);
            } else {
                idempotencyManager.releaseLock(idempotencyKey);
            }

            return result;

        } catch (ExtensionException e) {
            idempotencyManager.releaseLock(idempotencyKey);
            return ErrorResponseBuilder.buildErrorResponse(e);
        }
    }

    private Map<String, Object> executeCreateRecord(Map<String, Object> params) {
        // Validate
        validateInput(params);

        // Build payload
        Map<String, Object> payload = buildPayload(params);

        // Make API call
        ApiResponse response = client.post("/records", payload);

        if (response.isSuccess()) {
            return ErrorResponseBuilder.buildSuccessResponse(Map.of(
                "recordId", response.getString("id"),
                "createdAt", response.getString("created_at")
            ));
        } else {
            throw ApiErrorMapper.mapApiError(response);
        }
    }

    // For idempotent operations (like GET), no idempotency key needed
    @CatalogRequest(
        name = "Get Record",
        domain = "Records",
        type = CatalogRequest.Type.QUERY_SYSTEM
    )
    public Map<String, Object> getRecord(Map<String, Object> params) {
        String recordId = (String) params.get("Record ID");

        // Execute with retry (GET is naturally idempotent)
        return retryExecutor.execute(
            () -> {
                ApiResponse response = client.get("/records/" + recordId);

                if (response.isSuccess()) {
                    return ErrorResponseBuilder.buildSuccessResponse(
                        response.getData()
                    );
                } else {
                    throw ApiErrorMapper.mapApiError(response);
                }
            },
            "GetRecord"
        );
    }
}
```

## 5. Write Unit Tests

```java
package {{PACKAGE_NAME}}.retry;

import {{PACKAGE_NAME}}.error.*;
import org.junit.jupiter.api.*;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

class RetryExecutorTest {

    private RetryExecutor executor;

    @BeforeEach
    void setUp() {
        executor = new RetryExecutor(
            RetryConfig.builder()
                .maxAttempts(3)
                .initialDelay(Duration.ofMillis(10))
                .maxDelay(Duration.ofMillis(100))
                .build()
        );
    }

    @Test
    void execute_successOnFirstAttempt_returnsResult() {
        String result = executor.execute(() -> "success", "test");
        assertEquals("success", result);
    }

    @Test
    void execute_successOnSecondAttempt_retriesAndReturns() {
        AtomicInteger attempts = new AtomicInteger(0);

        String result = executor.execute(() -> {
            if (attempts.incrementAndGet() < 2) {
                throw ExtensionException.systemError("Temporary failure", null, true);
            }
            return "success";
        }, "test");

        assertEquals("success", result);
        assertEquals(2, attempts.get());
    }

    @Test
    void execute_allAttemptsFail_throwsException() {
        AtomicInteger attempts = new AtomicInteger(0);

        assertThrows(ExtensionException.class, () -> {
            executor.execute(() -> {
                attempts.incrementAndGet();
                throw ExtensionException.systemError("Always fails", null, true);
            }, "test");
        });

        assertEquals(3, attempts.get());
    }

    @Test
    void execute_nonRetryableError_doesNotRetry() {
        AtomicInteger attempts = new AtomicInteger(0);

        assertThrows(ExtensionException.class, () -> {
            executor.execute(() -> {
                attempts.incrementAndGet();
                throw ExtensionException.inputError("Invalid input");
            }, "test");
        });

        assertEquals(1, attempts.get());
    }
}

class IdempotencyManagerTest {

    private IdempotencyManager manager;

    @BeforeEach
    void setUp() {
        manager = new IdempotencyManager(60000); // 1 minute TTL
    }

    @Test
    void generateKey_sameParams_returnsSameKey() {
        Map<String, Object> params = Map.of("name", "test", "value", 123);

        String key1 = manager.generateKey("CreateRecord", params);
        String key2 = manager.generateKey("CreateRecord", params);

        assertEquals(key1, key2);
    }

    @Test
    void generateKey_differentParams_returnsDifferentKey() {
        String key1 = manager.generateKey("CreateRecord", Map.of("name", "test1"));
        String key2 = manager.generateKey("CreateRecord", Map.of("name", "test2"));

        assertNotEquals(key1, key2);
    }

    @Test
    void cacheResult_canBeRetrieved() {
        String key = "test-key";
        Map<String, Object> result = Map.of("success", true, "id", "123");

        manager.cacheResult(key, result);
        Map<String, Object> cached = manager.getCachedResult(key);

        assertEquals(result, cached);
    }

    @Test
    void tryAcquireLock_preventsDuplicates() {
        String key = "test-key";

        assertTrue(manager.tryAcquireLock(key));
        assertFalse(manager.tryAcquireLock(key));
    }

    @Test
    void releaseLock_allowsNewAcquisition() {
        String key = "test-key";

        manager.tryAcquireLock(key);
        manager.releaseLock(key);

        assertTrue(manager.tryAcquireLock(key));
    }
}
```

## Validation Checklist

- [ ] Retry config has sensible defaults
- [ ] Exponential backoff with jitter is implemented
- [ ] Non-retryable errors are not retried
- [ ] Idempotency keys are deterministic
- [ ] Cached results have TTL
- [ ] Locks prevent duplicate in-flight requests
- [ ] Unit tests cover retry and idempotency scenarios

## Best Practices

1. **Retry only retryable errors** - Don't retry input or auth errors
2. **Use exponential backoff** - Prevent thundering herd
3. **Add jitter** - Spread out retry attempts
4. **Set max attempts** - Don't retry forever
5. **Generate deterministic keys** - Same input = same key
6. **Set appropriate TTL** - Balance memory vs duplicate prevention
7. **Log retry attempts** - For debugging and monitoring

## Related Prompts

- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [16 - Implement Error Handling](16-implement-error-handling.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

