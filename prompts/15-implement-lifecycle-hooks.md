# Prompt 15: Implement Extension Lifecycle Hooks

## Purpose

Implement the extension lifecycle hooks (INVOKER_LOADED, INVOKER_UPDATED, INVOKER_UNLOADED) to properly initialize, update, and clean up extension resources when the extension is loaded, configuration changes, or is unloaded.

## Prerequisites

- Existing extension class with `@Extension` annotation
- Understanding of resources that need initialization/cleanup

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |

---

## Prompt

```
I need you to implement comprehensive lifecycle hooks for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Implement All Lifecycle Hooks

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.integration.WebhookManager;
import {{PACKAGE_NAME}}.integration.TokenManager;

import java.util.*;
import java.util.concurrent.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_NAME}} Integration"
)
public class {{EXTENSION_NAME}}Extension {

    private static final Logger logger = LoggerFactory.getLogger({{EXTENSION_NAME}}Extension.class);

    // ============================================================
    // EXTENSION STATE
    // ============================================================
    
    private Map<String, Object> attributes;
    private String invokerId;
    
    // Managed resources
    private ApiClient apiClient;
    private TokenManager tokenManager;
    private WebhookManager webhookManager;
    private ScheduledExecutorService scheduler;
    private boolean initialized = false;

    // ============================================================
    // LIFECYCLE: INVOKER_LOADED
    // ============================================================

    /**
     * Called when the extension is first loaded.
     * 
     * Use this to:
     * - Store configuration attributes
     * - Initialize API clients
     * - Set up scheduled tasks
     * - Register webhooks
     * - Initialize caches
     * 
     * @param attributes Configuration from Setup tab
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        logger.info("Extension loading with attributes: {}", 
            maskSensitiveAttributes(attributes));
        
        this.attributes = new HashMap<>(attributes);
        this.invokerId = getString(AttributeKeys.INVOKER_ID);
        
        try {
            // Initialize core components
            initializeTokenManager();
            initializeApiClient();
            
            // Initialize optional components
            initializeScheduler();
            initializeWebhooks();
            
            this.initialized = true;
            logger.info("Extension loaded successfully");
            
        } catch (Exception e) {
            logger.error("Failed to initialize extension", e);
            cleanup();
            throw new RuntimeException("Extension initialization failed: " + e.getMessage(), e);
        }
    }

    // ============================================================
    // LIFECYCLE: INVOKER_UPDATED
    // ============================================================

    /**
     * Called when extension configuration is updated.
     * 
     * Use this to:
     * - Detect what changed
     * - Reinitialize affected components
     * - Update webhooks if URL changed
     * - Refresh tokens if credentials changed
     * 
     * @param oldAttributes Previous configuration
     * @param newAttributes New configuration
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttributes, Map<String, Object> newAttributes) {
        logger.info("Extension configuration updated");
        
        try {
            // Detect what changed
            Set<String> changedKeys = detectChanges(oldAttributes, newAttributes);
            logger.debug("Changed attributes: {}", changedKeys);
            
            // Update stored attributes
            this.attributes = new HashMap<>(newAttributes);
            
            // Handle credential changes
            if (credentialsChanged(changedKeys)) {
                logger.info("Credentials changed, reinitializing authentication");
                reinitializeAuthentication();
            }
            
            // Handle connection settings changes
            if (connectionSettingsChanged(changedKeys)) {
                logger.info("Connection settings changed, reinitializing client");
                reinitializeApiClient();
            }
            
            // Handle webhook URL changes
            if (webhookSettingsChanged(changedKeys)) {
                logger.info("Webhook settings changed, updating webhooks");
                updateWebhooks(oldAttributes, newAttributes);
            }
            
            // Handle scheduler settings changes
            if (schedulerSettingsChanged(changedKeys)) {
                logger.info("Scheduler settings changed, reinitializing scheduler");
                reinitializeScheduler();
            }
            
            logger.info("Extension configuration update complete");
            
        } catch (Exception e) {
            logger.error("Failed to update extension configuration", e);
            throw new RuntimeException("Configuration update failed: " + e.getMessage(), e);
        }
    }

    // ============================================================
    // LIFECYCLE: INVOKER_UNLOADED
    // ============================================================

    /**
     * Called when the extension is being unloaded.
     * 
     * Use this to:
     * - Close API connections
     * - Stop scheduled tasks
     * - Unregister webhooks
     * - Release resources
     * - Flush caches
     * 
     * @param attributes Current configuration
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_UNLOADED)
    public void onUnloaded(Map<String, Object> attributes) {
        logger.info("Extension unloading");

        cleanup();

        logger.info("Extension unloaded successfully");
    }

    // ============================================================
    // INITIALIZATION METHODS
    // ============================================================

    private void initializeTokenManager() {
        String clientId = getString(AttributeKeys.CLIENT_ID);
        String clientSecret = getString(AttributeKeys.CLIENT_SECRET);
        String tokenUrl = getString(AttributeKeys.BASE_URL) + "/oauth/token";

        this.tokenManager = new TokenManager(clientId, clientSecret, tokenUrl);
        logger.debug("Token manager initialized");
    }

    private void initializeApiClient() {
        String baseUrl = getString(AttributeKeys.BASE_URL);
        int timeout = getInt(AttributeKeys.TIMEOUT_SECONDS, 30);

        this.apiClient = new ApiClient(baseUrl, tokenManager, timeout);
        logger.debug("API client initialized with base URL: {}", baseUrl);
    }

    private void initializeScheduler() {
        // Only initialize if polling is enabled
        if (getBoolean(AttributeKeys.ENABLE_POLLING)) {
            this.scheduler = Executors.newScheduledThreadPool(2);

            int pollInterval = getInt(AttributeKeys.POLL_INTERVAL_MINUTES, 5);
            scheduler.scheduleAtFixedRate(
                this::pollForUpdates,
                pollInterval,
                pollInterval,
                TimeUnit.MINUTES
            );

            logger.debug("Scheduler initialized with {} minute interval", pollInterval);
        }
    }

    private void initializeWebhooks() {
        String webhookUrl = getString(AttributeKeys.WEBHOOK_URL);
        if (webhookUrl != null && !webhookUrl.isBlank()) {
            this.webhookManager = new WebhookManager(apiClient);
            webhookManager.registerWebhook(webhookUrl, invokerId);
            logger.debug("Webhook registered at: {}", webhookUrl);
        }
    }

    // ============================================================
    // REINITIALIZATION METHODS
    // ============================================================

    private void reinitializeAuthentication() {
        // Invalidate existing tokens
        if (tokenManager != null) {
            tokenManager.invalidateTokens();
        }

        // Reinitialize token manager with new credentials
        initializeTokenManager();

        // Update API client with new token manager
        if (apiClient != null) {
            apiClient.setTokenManager(tokenManager);
        }
    }

    private void reinitializeApiClient() {
        // Close existing client
        if (apiClient != null) {
            apiClient.close();
        }

        // Create new client
        initializeApiClient();
    }

    private void reinitializeScheduler() {
        // Stop existing scheduler
        if (scheduler != null) {
            scheduler.shutdown();
            try {
                scheduler.awaitTermination(10, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
            }
        }

        // Start new scheduler if enabled
        initializeScheduler();
    }

    private void updateWebhooks(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        String oldUrl = getString(oldAttrs, AttributeKeys.WEBHOOK_URL);
        String newUrl = getString(newAttrs, AttributeKeys.WEBHOOK_URL);

        // Unregister old webhook
        if (oldUrl != null && !oldUrl.isBlank() && webhookManager != null) {
            webhookManager.unregisterWebhook(oldUrl);
        }

        // Register new webhook
        if (newUrl != null && !newUrl.isBlank()) {
            if (webhookManager == null) {
                webhookManager = new WebhookManager(apiClient);
            }
            webhookManager.registerWebhook(newUrl, invokerId);
        }
    }

    // ============================================================
    // CHANGE DETECTION METHODS
    // ============================================================

    private Set<String> detectChanges(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        Set<String> changed = new HashSet<>();

        // Check all keys in new attributes
        for (String key : newAttrs.keySet()) {
            Object oldValue = oldAttrs.get(key);
            Object newValue = newAttrs.get(key);

            if (!Objects.equals(oldValue, newValue)) {
                changed.add(key);
            }
        }

        // Check for removed keys
        for (String key : oldAttrs.keySet()) {
            if (!newAttrs.containsKey(key)) {
                changed.add(key);
            }
        }

        return changed;
    }

    private boolean credentialsChanged(Set<String> changedKeys) {
        return changedKeys.contains(AttributeKeys.CLIENT_ID) ||
               changedKeys.contains(AttributeKeys.CLIENT_SECRET) ||
               changedKeys.contains(AttributeKeys.API_KEY);
    }

    private boolean connectionSettingsChanged(Set<String> changedKeys) {
        return changedKeys.contains(AttributeKeys.BASE_URL) ||
               changedKeys.contains(AttributeKeys.TIMEOUT_SECONDS) ||
               changedKeys.contains(AttributeKeys.API_VERSION);
    }

    private boolean webhookSettingsChanged(Set<String> changedKeys) {
        return changedKeys.contains(AttributeKeys.WEBHOOK_URL);
    }

    private boolean schedulerSettingsChanged(Set<String> changedKeys) {
        return changedKeys.contains(AttributeKeys.ENABLE_POLLING) ||
               changedKeys.contains(AttributeKeys.POLL_INTERVAL_MINUTES);
    }

    // ============================================================
    // CLEANUP METHODS
    // ============================================================

    private void cleanup() {
        // Stop scheduler
        if (scheduler != null) {
            logger.debug("Shutting down scheduler");
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(10, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
            scheduler = null;
        }

        // Unregister webhooks
        if (webhookManager != null) {
            logger.debug("Unregistering webhooks");
            try {
                webhookManager.unregisterAll();
            } catch (Exception e) {
                logger.warn("Failed to unregister webhooks", e);
            }
            webhookManager = null;
        }

        // Close API client
        if (apiClient != null) {
            logger.debug("Closing API client");
            try {
                apiClient.close();
            } catch (Exception e) {
                logger.warn("Failed to close API client", e);
            }
            apiClient = null;
        }

        // Clear token manager
        if (tokenManager != null) {
            tokenManager.invalidateTokens();
            tokenManager = null;
        }

        this.initialized = false;
    }

    // ============================================================
    // UTILITY METHODS
    // ============================================================

    private String getString(String key) {
        return getString(attributes, key);
    }

    private String getString(Map<String, Object> attrs, String key) {
        Object value = attrs.get(key);
        return value != null ? value.toString() : null;
    }

    private int getInt(String key, int defaultValue) {
        String value = getString(key);
        if (value == null || value.isBlank()) return defaultValue;
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private boolean getBoolean(String key) {
        return "true".equalsIgnoreCase(getString(key));
    }

    private Map<String, Object> maskSensitiveAttributes(Map<String, Object> attrs) {
        Map<String, Object> masked = new HashMap<>(attrs);
        Set<String> sensitiveKeys = Set.of(
            AttributeKeys.CLIENT_SECRET,
            AttributeKeys.API_KEY,
            AttributeKeys.PASSWORD
        );

        for (String key : sensitiveKeys) {
            if (masked.containsKey(key)) {
                masked.put(key, "***MASKED***");
            }
        }

        return masked;
    }

    private void pollForUpdates() {
        // Implement polling logic here
        logger.debug("Polling for updates...");
    }

    // ============================================================
    // GETTERS FOR AREAS
    // ============================================================

    public ApiClient getApiClient() {
        if (!initialized) {
            throw new IllegalStateException("Extension not initialized");
        }
        return apiClient;
    }

    public Map<String, Object> getAttributes() {
        return Collections.unmodifiableMap(attributes);
    }

    public boolean isInitialized() {
        return initialized;
    }
}
```

## 2. Lifecycle Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Extension Lifecycle                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                               │
│  │ Extension    │                                               │
│  │ Deployed     │                                               │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐     ┌─────────────────────────────────────┐   │
│  │ INVOKER_     │────▶│ • Store attributes                  │   │
│  │ LOADED       │     │ • Initialize API client             │   │
│  └──────┬───────┘     │ • Start scheduler                   │   │
│         │             │ • Register webhooks                 │   │
│         │             └─────────────────────────────────────┘   │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ Running      │◀────────────────────────────┐                 │
│  └──────┬───────┘                             │                 │
│         │                                     │                 │
│         ▼                                     │                 │
│  ┌──────────────┐     ┌─────────────────────────────────────┐   │
│  │ INVOKER_     │────▶│ • Detect changes                    │   │
│  │ UPDATED      │     │ • Reinitialize affected components  │───┘
│  └──────┬───────┘     │ • Update webhooks                   │   │
│         │             └─────────────────────────────────────┘   │
│         ▼                                                       │
│  ┌──────────────┐     ┌─────────────────────────────────────┐   │
│  │ INVOKER_     │────▶│ • Stop scheduler                    │   │
│  │ UNLOADED     │     │ • Unregister webhooks               │   │
│  └──────────────┘     │ • Close connections                 │   │
│                       │ • Release resources                 │   │
│                       └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 3. Write Unit Tests

```java
package {{PACKAGE_NAME}};

import org.junit.jupiter.api.*;
import org.mockito.*;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class {{EXTENSION_NAME}}ExtensionLifecycleTest {

    private {{EXTENSION_NAME}}Extension extension;

    @BeforeEach
    void setUp() {
        extension = new {{EXTENSION_NAME}}Extension();
    }

    @Test
    void onLoaded_initializesExtension() {
        Map<String, Object> attrs = createValidAttributes();

        extension.onLoaded(attrs);

        assertTrue(extension.isInitialized());
        assertNotNull(extension.getApiClient());
    }

    @Test
    void onUpdated_detectsCredentialChanges() {
        Map<String, Object> oldAttrs = createValidAttributes();
        Map<String, Object> newAttrs = new HashMap<>(oldAttrs);
        newAttrs.put("Client Secret", "new-secret");

        extension.onLoaded(oldAttrs);
        extension.onUpdated(oldAttrs, newAttrs);

        // Verify token manager was reinitialized
        assertTrue(extension.isInitialized());
    }

    @Test
    void onUnloaded_cleansUpResources() {
        Map<String, Object> attrs = createValidAttributes();
        extension.onLoaded(attrs);

        extension.onUnloaded(attrs);

        assertFalse(extension.isInitialized());
    }

    @Test
    void onLoaded_withInvalidConfig_throwsException() {
        Map<String, Object> attrs = new HashMap<>();
        // Missing required fields

        assertThrows(RuntimeException.class, () -> extension.onLoaded(attrs));
    }

    private Map<String, Object> createValidAttributes() {
        Map<String, Object> attrs = new HashMap<>();
        attrs.put("Base URL", "https://api.example.com");
        attrs.put("Client ID", "test-client-id");
        attrs.put("Client Secret", "test-secret");
        attrs.put("Timeout (seconds)", "30");
        return attrs;
    }
}
```

## Validation Checklist

- [ ] INVOKER_LOADED initializes all required resources
- [ ] INVOKER_UPDATED detects and handles all change types
- [ ] INVOKER_UNLOADED releases all resources properly
- [ ] Sensitive attributes are masked in logs
- [ ] Errors during initialization are handled gracefully
- [ ] Scheduler is properly shut down on unload
- [ ] Webhooks are unregistered on unload

## Best Practices

1. **Initialize lazily** - Only create resources when needed
2. **Detect changes** - Only reinitialize what actually changed
3. **Clean up properly** - Always release resources in INVOKER_UNLOADED
4. **Handle errors** - Don't let initialization failures crash the extension
5. **Log appropriately** - Log lifecycle events but mask sensitive data
6. **Thread safety** - Use proper synchronization for shared state

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [13 - Implement VALIDATE_ATTRIBUTES](13-implement-validate-attributes.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
```

