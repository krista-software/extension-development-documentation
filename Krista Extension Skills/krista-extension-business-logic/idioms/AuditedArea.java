// IDIOM — the "compact" Area boundary: one audited() wrapper carries try/catch -> classify ->
// ExtensionResponse + telemetry + timing, so each @CatalogRequest method holds only business logic.
package {{PACKAGE}}.catalog;

import app.krista.extension.executor.ExtensionResponse;
import app.krista.extension.executor.ExtensionResponse.Error.ExceptionType;
import app.krista.extension.executor.Invoker;
import app.krista.extension.impl.anno.*;
import {{PACKAGE}}.catalog.extresp.ExtensionResponseFactory;
import {{PACKAGE}}.catalog.extresp.TelemetryHelper;
import {{PACKAGE}}.integration.{{ATTR_STORE_CLASS}};
import {{PACKAGE}}.integration.{{CLIENT_CLASS}};
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import java.util.LinkedHashMap;
import java.util.Map;

@Domain(id = "{{DOMAIN_ID}}", name = "{{DOMAIN_NAME}}",
        ecosystemId = "{{ECOSYSTEM_ID}}", ecosystemName = "{{ECOSYSTEM_NAME}}", ecosystemVersion = "{{ECOSYSTEM_VERSION}}")
public class {{AREA_CLASS}} {

    private static final Logger LOG = LoggerFactory.getLogger({{AREA_CLASS}}.class);
    private static final String PREFIX = "{{TELEMETRY_PREFIX}}";   // e.g. "github"

    private final {{ATTR_STORE_CLASS}} attributeStore;
    private final TelemetryHelper telemetry;
    private final String invokerId;

    @Inject
    public {{AREA_CLASS}}({{ATTR_STORE_CLASS}} attributeStore, TelemetryHelper telemetry, Invoker invoker) {
        this.attributeStore = attributeStore;
        this.telemetry = telemetry;
        this.invokerId = invoker.getInvokerId();          // multi-tenant scope
    }

    // ---- the catalog request: thin; all boilerplate lives in audited() ----
    @CatalogRequest(id = "{{REQUEST_ID}}", name = "{{REQUEST_NAME}}", area = "{{AREA_LABEL}}",
            type = CatalogRequest.Type.CHANGE_SYSTEM, tool = true)
    @Field.Boolean(name = "Success", required = false)
    public ExtensionResponse createThing(
            @Field.Text(name = "Name", required = true, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) String name,
            @Field(name = "Description", type = "Paragraph", required = false, attributes = {}, options = {}) String description) {
        return audited("CreateThing", () -> {
            {{CLIENT_CLASS}} client = getClient();
            JsonObject body = new JsonObject();
            body.addProperty("name", name);
            if (description != null && !description.isBlank()) body.addProperty("description", description); // only non-blank
            JsonObject result = client.post("/things", body);
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("Success", true);
            out.put("Id", result.get("id").getAsString());
            return ExtensionResponseFactory.ok(out);
        });
    }

    // ---- the uniform wrapper ----
    @FunctionalInterface interface CheckedSupplier<T> { T get() throws Exception; }

    private ExtensionResponse audited(String name, CheckedSupplier<ExtensionResponse> action) {
        long t0 = telemetry.start(PREFIX + "." + name);
        LOG.info("Catalog '{}' started for invoker {}", name, invokerId);
        try {
            ExtensionResponse r = action.get();
            LOG.info("Catalog '{}' ok in {}ms for invoker {}", name, System.currentTimeMillis() - t0, invokerId);
            telemetry.recordSuccess(PREFIX + "." + name, t0, Map.of());
            return r;
        } catch (SecurityException e) {                 // AUTH
            LOG.error("Catalog '{}' AUTH: {}", name, e.getMessage());
            telemetry.recordError(PREFIX + "." + name, t0, e, Map.of());
            return ExtensionResponseFactory.failure(e.getMessage(), ExceptionType.AUTHENTICATION_ERROR);
        } catch (IllegalArgumentException e) {           // INPUT
            LOG.warn("Catalog '{}' INPUT: {}", name, e.getMessage());
            telemetry.recordError(PREFIX + "." + name, t0, e, Map.of());
            return ExtensionResponseFactory.failure(e.getMessage(), ExceptionType.INPUT_ERROR);
        } catch (Exception e) {                          // SYSTEM
            LOG.error("Catalog '{}' SYSTEM: {}", name, e.getMessage(), e);
            telemetry.recordError(PREFIX + "." + name, t0, e, Map.of());
            return ExtensionResponseFactory.failure(e.getMessage(), ExceptionType.SYSTEM_ERROR);
        }
        // NOTE: for interactive-auth extensions, catch MustAuthorize/MustAuthenticateException FIRST and RE-THROW it.
    }

    private {{CLIENT_CLASS}} getClient() {
        {{ATTRS_CLASS}} attrs = attributeStore.load(invokerId);
        if (attrs == null) throw new IllegalStateException("Not configured — complete the Setup tab.");
        return new {{CLIENT_CLASS}}(attrs);           // fresh client per request
    }
}
