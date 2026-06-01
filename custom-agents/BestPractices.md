<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Custom agents](README.md) > Best practices

# Best practices

## Overview

This page provides best practices and recommendations for developing robust, maintainable, and performant custom agent extensions.

## Architecture and design

### 1. Separate concerns

Follow the layered architecture pattern used throughout Krista extensions:

```
Controller (Catalog Requests)
    ↓
Transformation (Data Mapping)
    ↓
Integration (External Services)
```

See: [Layered architecture](../architecture/LayeredArchitecture.md)

### 2. Keep the hosting URL endpoint simple

The `/hostUrl` endpoint should be lightweight and fast:

```java
// Good: Simple, cached response
@GET
@Path("/hostUrl")
public String getHostingUrl() {
    return cachedHostUrlResponse;
}

// Bad: Heavy processing
@GET
@Path("/hostUrl")
public String getHostingUrl() {
    // Don't do this!
    validateConfiguration();
    checkDatabaseConnection();
    loadDynamicSettings();
    return buildResponse();
}
```

### 3. Use meaningful identifiers

Choose clear, descriptive IDs for catalog requests:

```java
// Good: Descriptive and unique
@CatalogRequest(
    id = "conversation_agent_analyze_sentiment_v1",
    name = "Analyze Conversation Sentiment",
    // ...
)

// Bad: Generic or unclear
@CatalogRequest(
    id = "req123",
    name = "Do Something",
    // ...
)
```

## Performance

### 1. Optimize response times

Target response times for key operations:

| Operation | Target | Maximum |
|-----------|--------|---------|
| `/hostUrl` endpoint | < 200ms | < 500ms |
| Dashboard load | < 2s | < 5s |
| Catalog requests | < 1s | < 3s |

### 2. Implement caching

Cache static or infrequently changing data:

```java
private static final String CACHED_HOST_URL = 
    System.getenv("AGENT_HOST_URL");

@GET
@Path("/hostUrl")
public String getHostingUrl() {
    Map<String, Object> wrapper = new HashMap<>();
    Map<String, String> payload = new HashMap<>();
    payload.put("hostingUrl", CACHED_HOST_URL);
    wrapper.put("payload", payload);
    return new Gson().toJson(wrapper);
}
```

### 3. Minimize external API calls

Reduce latency by minimizing external dependencies:

- Cache API responses when appropriate
- Use batch operations where possible
- Implement circuit breakers for external services

See: [Minimizing external API calls](../performance/MinimizingExternalAPICalls.md)

## Security

### 1. Use HTTPS exclusively

Never use HTTP for production deployments:

```java
// Good: HTTPS URL
payload.put("hostingUrl", "https://agent.example.com/");

// Bad: HTTP URL (insecure)
payload.put("hostingUrl", "http://agent.example.com/");
```

### 2. Validate all inputs

Always validate inputs to catalog requests:

```java
@CatalogRequest(
    id = "conversation_agent_process_query",
    name = "Process User Query",
    // ...
)
public ExtensionResponse processQuery(QueryRequest request) {
    // Validate inputs
    if (request == null || request.getQuery() == null) {
        throw new IllegalArgumentException("Query cannot be null");
    }
    
    if (request.getQuery().length() > MAX_QUERY_LENGTH) {
        throw new IllegalArgumentException("Query exceeds maximum length");
    }
    
    // Process request
    return handleQuery(request);
}
```

### 3. Sanitize user input

Prevent injection attacks by sanitizing user input:

```java
String sanitizedQuery = sanitizeInput(request.getQuery());
```

### 4. Implement rate limiting

Protect your agent from abuse:

```java
@RateLimit(requests = 100, per = TimeUnit.MINUTES)
@CatalogRequest(/* ... */)
public ExtensionResponse processQuery(QueryRequest request) {
    // Implementation
}
```

## Error handling

### 1. Provide meaningful error messages

Return clear, actionable error messages:

```java
// Good: Specific, actionable error
throw new ValidationException(
    "Query must be between 1 and 1000 characters. Received: " + 
    query.length() + " characters"
);

// Bad: Generic error
throw new Exception("Invalid input");
```

### 2. Use appropriate error types

Map errors to the correct error types:

```java
// Input validation errors
throw new InputErrorException("Invalid query format");

// Business logic errors
throw new LogicErrorException("Agent not configured");

// System errors
throw new SystemErrorException("Failed to connect to AI service");
```

See: [Error handling](../operations/ErrorHandling.md)

### 3. Handle unsupported operations gracefully

```java
@Override
public ExtensionResponse unsupportedOperation() {
    throw new UnsupportedOperationException(
        "This operation is not supported by the Conversation Agent. " +
        "Please refer to the documentation for supported operations."
    );
}
```

## Testing

### 1. Test in Private Catalog first

Always test thoroughly before deploying to Global Catalog:

```
Local Development → Private Catalog → Validation → Global Catalog
```

### 2. Implement comprehensive unit tests

Test all catalog requests and core functionality:

```java
@Test
public void testProcessQuery_ValidInput_ReturnsResponse() {
    QueryRequest request = new QueryRequest("What is the weather?");
    ExtensionResponse response = agent.processQuery(request);
    
    assertNotNull(response);
    assertEquals(ResponseStatus.SUCCESS, response.getStatus());
}

@Test
public void testProcessQuery_NullInput_ThrowsException() {
    assertThrows(IllegalArgumentException.class, () -> {
        agent.processQuery(null);
    });
}
```

See: [Testing strategy](../development/TestingStrategy.md)

### 3. Test dashboard embedding

Verify your dashboard works correctly in an iframe:

- Test in different browsers
- Verify responsive design
- Check for CORS issues
- Test all interactive features

## Documentation

### 1. Document all catalog requests

Provide clear documentation for each catalog request:

```java
/**
 * Processes user queries and generates intelligent responses.
 * 
 * @param request The query request containing user input
 * @return ExtensionResponse with the generated response
 * @throws IllegalArgumentException if request is null or invalid
 * @throws SystemErrorException if AI service is unavailable
 */
@CatalogRequest(
    id = "conversation_agent_process_query",
    name = "Process User Query",
    description = "Processes user queries using AI and returns intelligent responses",
    area = "Agent",
    type = CatalogRequest.Type.CHANGE_SYSTEM
)
public ExtensionResponse processQuery(QueryRequest request) {
    // Implementation
}
```

### 2. Maintain a changelog

Track changes across versions:

```markdown
## Version 1.2.0 (2024-01-15)

### Added
- Sentiment analysis for conversations
- Multi-language support

### Changed
- Improved response generation algorithm
- Updated hosting URL endpoint performance

### Fixed
- Dashboard loading issue in Safari
- CORS configuration for production environment
```

### 3. Provide user documentation

Create user-facing documentation:

- Getting started guide
- Feature overview
- Troubleshooting guide
- FAQ

## Monitoring and observability

### 1. Implement logging

Log important events and errors:

```java
private static final Logger logger = LoggerFactory.getLogger(ConversationAgent.class);

@CatalogRequest(/* ... */)
public ExtensionResponse processQuery(QueryRequest request) {
    logger.info("Processing query: {}", sanitizeForLog(request.getQuery()));
    
    try {
        ExtensionResponse response = handleQuery(request);
        logger.info("Query processed successfully");
        return response;
    } catch (Exception e) {
        logger.error("Failed to process query", e);
        throw e;
    }
}
```

See: [Observability](../operations/Observability.md)

### 2. Track metrics

Monitor key performance indicators:

- Request count
- Response times
- Error rates
- User engagement

### 3. Set up alerts

Configure alerts for critical issues:

- High error rates
- Slow response times
- Service unavailability
- Unusual usage patterns

## Maintenance

### 1. Plan for updates

Design your agent for easy updates:

- Use configuration files for settings
- Implement feature flags
- Support backward compatibility
- Provide migration paths

### 2. Monitor after deployment

After deploying to Global Catalog:

- Review error logs daily
- Track usage metrics
- Collect user feedback
- Plan iterative improvements

### 3. Respond to issues quickly

Establish a process for handling production issues:

1. Monitor alerts and user reports
2. Investigate and diagnose issues
3. Implement fixes
4. Test thoroughly
5. Deploy updates
6. Communicate with users

## See also

- [Layered architecture](../architecture/LayeredArchitecture.md)
- [Testing strategy](../development/TestingStrategy.md)
- [Error handling](../operations/ErrorHandling.md)
- [Observability](../operations/Observability.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).

