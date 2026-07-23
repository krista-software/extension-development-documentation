<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Custom agents](README.md) > Hosting URL endpoint

# Hosting URL endpoint

## Overview

Your custom agent extension must expose a REST endpoint that tells the Krista platform where your agent's web-based dashboard is hosted. This is the only endpoint Krista calls automatically to discover and embed your agent's user interface.

## Endpoint requirements

### JAX-RS configuration

- **JAX-RS ID**: `default REST`
- **Endpoint path**: `/hostUrl`
- **HTTP method**: `GET`
- **Response type**: `application/json`

### Response structure

The endpoint must return a JSON object with the following structure:

```json
{
  "payload": {
    "hostingUrl": "https://your-agent.example.com/"
  }
}
```

## Implementation

### Java example

```java
@GET
@Path("/hostUrl")
public String getHostingUrl() {
    Map<String, Object> wrapper = new HashMap<>();
    Map<String, String> payload = new HashMap<>();
    
    // The hosting URL for your agent extension service
    payload.put("hostingUrl", "https://conversation-agent.uslab.krista.app/");
    wrapper.put("payload", payload);
    
    return new Gson().toJson(wrapper);
}
```

### Response example

```json
{
  "payload": {
    "hostingUrl": "https://conversation-agent.uslab.krista.app/"
  }
}
```

## Best practices

### 1. Use stable URLs

The hosting URL must be:
- Publicly accessible
- Stable (not subject to frequent changes)
- Secured with HTTPS (required)

### 2. Optimize response time

- Target response time: < 500ms
- The platform calls this endpoint frequently
- Avoid heavy processing or external API calls
- Consider caching the URL value

### 3. Environment-specific URLs

Use configuration or environment variables to manage different URLs across environments:

```java
@GET
@Path("/hostUrl")
public String getHostingUrl() {
    String baseUrl = System.getenv("AGENT_HOST_URL");
    if (baseUrl == null) {
        baseUrl = "https://default-agent.example.com/";
    }
    
    Map<String, Object> wrapper = new HashMap<>();
    Map<String, String> payload = new HashMap<>();
    payload.put("hostingUrl", baseUrl);
    wrapper.put("payload", payload);
    
    return new Gson().toJson(wrapper);
}
```

## Validation

### Testing the endpoint

Test your endpoint locally before deployment:

```bash
curl -X GET https://your-agent.example.com/hostUrl
```

Expected response:

```json
{
  "payload": {
    "hostingUrl": "https://your-agent.example.com/"
  }
}
```

### Common issues

| Issue | Cause | Resolution |
|-------|-------|------------|
| 404 Not Found | Incorrect path or JAX-RS configuration | Verify path is `/hostUrl` and JAX-RS ID is `default REST` |
| Slow response | Heavy processing in endpoint | Remove processing logic; return cached value |
| CORS errors | Missing CORS headers | Configure CORS to allow Krista platform domain |
| Invalid JSON | Incorrect response structure | Ensure `payload` wrapper and `hostingUrl` key exist |

## Security considerations

1. **HTTPS only**: Never use HTTP for production deployments
2. **Authentication**: The endpoint should be publicly accessible (no authentication required)
3. **Rate limiting**: Implement rate limiting to prevent abuse
4. **Input validation**: Although this is a GET endpoint with no parameters, validate any future additions

## See also

- [Domain registration](DomainRegistration.md)
- [API requests](../reference/ApiRequests.md)
- [Deployment and configuration](../operations/DeploymentAndConfiguration.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).

