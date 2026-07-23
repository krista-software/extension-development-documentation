// IDIOM — production HTTP connector. Adapt names/paths; this is not compile-as-is.
// Pattern: one shared OkHttpClient (pooled + 3 timeouts from config), cross-cutting concerns as
// interceptors, ONE execute() path, centralized Gson, verbs incl. 204, single error-mapping point.
package {{PACKAGE}}.integration;

import com.google.gson.*;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

public class {{CLIENT_CLASS}} {

    private static final Logger LOG = LoggerFactory.getLogger({{CLIENT_CLASS}}.class);
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final String baseUrl;
    private final String token;                 // or username/secret for header auth
    private final Gson gson;
    private final OkHttpClient http;

    public {{CLIENT_CLASS}}({{ATTRS_CLASS}} cfg) {
        this.baseUrl = cfg.getBaseUrl();        // already normalized (trailing slash stripped, https)
        this.token   = cfg.getToken();
        this.gson    = buildGson();
        this.http = new OkHttpClient.Builder()
                .connectionPool(new ConnectionPool(20, 5, TimeUnit.MINUTES))
                .connectTimeout(cfg.getTimeoutSeconds(), TimeUnit.SECONDS)
                .readTimeout(cfg.getTimeoutSeconds(), TimeUnit.SECONDS)   // = vendor execution ceiling
                .writeTimeout(cfg.getTimeoutSeconds(), TimeUnit.SECONDS)
                .addInterceptor(this::addAuthHeaders)     // auth
                .addInterceptor(new RetryInterceptor(cfg))// transient retry (see Interceptors.java)
                // .addInterceptor(new RateLimitInterceptor()) // if the API is rate-limited
                .build();
    }

    private Response addAuthHeaders(Interceptor.Chain chain) throws IOException {
        Request req = chain.request().newBuilder()
                .addHeader("Authorization", "Bearer " + token)
                .addHeader("Accept", "application/json")
                .build();
        LOG.info("API {} {} (auth=Bearer ****{})", req.method(), req.url(), last4(token));
        return chain.proceed(req);
    }

    // ---- verbs (thin over execute) ----
    public JsonObject get(String path) throws IOException {
        return parseObject(execute(new Request.Builder().url(baseUrl + path).get().build()));
    }
    public JsonObject post(String path, JsonObject body) throws IOException {
        return parseObject(execute(new Request.Builder().url(baseUrl + path)
                .post(RequestBody.create(body.toString(), JSON)).build()));
    }
    /** DELETE / dispatch endpoints that return 204 No Content — return the status code, don't parse. */
    public int postNoResponse(String path, JsonObject body) throws IOException {
        try (Response r = execute(new Request.Builder().url(baseUrl + path)
                .post(RequestBody.create(body.toString(), JSON)).build())) {
            return r.code();
        }
    }

    // ---- the single execute + parse + error-mapping path ----
    private Response execute(Request request) throws IOException {
        Response response = http.newCall(request).execute();
        if (!response.isSuccessful()) {
            handleErrorResponse(response);   // reads body + throws typed exception; closes below
        }
        return response;
    }

    private JsonObject parseObject(Response response) throws IOException {
        try (response) {
            String body = response.body() != null ? response.body().string() : "{}";
            return JsonParser.parseString(body).getAsJsonObject();
        }
    }

    /** SINGLE status -> typed exception mapping point. See Exceptions.java for the typed-hierarchy variant. */
    private void handleErrorResponse(Response response) throws IOException {
        int code = response.code();
        String body = response.body() != null ? response.body().string() : "";
        String apiMsg = extractMessage(body);
        LOG.error("API error: {} {} -> HTTP {} | message='{}'",
                response.request().method(), response.request().url(), code, apiMsg);
        response.close();
        switch (code) {
            case 401, 403 -> throw new SecurityException(withDetail("{{ERR_UNAUTHORIZED}}", apiMsg));
            case 404, 422 -> throw new IllegalArgumentException(withDetail("{{ERR_NOT_FOUND}}", apiMsg));
            case 409      -> throw new IllegalStateException(withDetail("{{ERR_CONFLICT}}", apiMsg));
            case 429      -> throw new IOException("Rate limited. Retry after a delay.");
            default       -> throw new IOException("API error (" + code + "): " + apiMsg);
        }
    }

    private Gson buildGson() {
        // register a vendor date adapter here if needed, e.g. strip trailing 'Z' before LocalDateTime.parse
        return new GsonBuilder().create();
    }
    private static String withDetail(String friendly, String api) {
        return (api == null || api.isBlank()) ? friendly : friendly + " (" + api + ")";
    }
    private static String extractMessage(String body) {
        try {
            JsonObject o = JsonParser.parseString(body).getAsJsonObject();
            if (o.has("message")) return o.get("message").getAsString();
        } catch (Exception ignored) {}
        return body.length() > 200 ? body.substring(0, 200) : body;
    }
    private static String last4(String s) { return (s == null || s.length() < 4) ? "" : s.substring(s.length() - 4); }
}
