// IDIOM — build ExtensionResponse consistently. Prefer ExtensionResponseBuilder; this factory shows
// the raw-constructor form + the failure/ExceptionType classification used by the audited wrapper.
package {{PACKAGE}}.catalog.extresp;

import app.krista.extension.executor.ExtensionResponse;
import app.krista.extension.executor.ExtensionResponseBuilder;
import app.krista.extension.executor.RemediationActions;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ExtensionResponseFactory {
    private ExtensionResponseFactory() {}

    // Simplest: the builder (equivalent to create(values) below).
    public static ExtensionResponse ok(Map<String, Object> values) {
        return new ExtensionResponseBuilder().success(values).build();
    }

    // Raw-constructor success (when you need the exact shape).
    public static ExtensionResponse create(Map<String, Object> values) {
        return new ExtensionResponse(ExtensionResponse.Result.SUCCESS, values, null, null, null);
    }

    // Failure with an ExceptionType classification (AUTHENTICATION_ERROR / INPUT_ERROR / SYSTEM_ERROR).
    public static ExtensionResponse failure(String message, ExtensionResponse.Error.ExceptionType type) {
        ExtensionResponse.Error error = new ExtensionResponse.Error(message, System.currentTimeMillis(), type, "");
        return new ExtensionResponse(ExtensionResponse.Result.FAILURE, null, error,
                new RemediationActions(List.of(), null), Map.of());
    }

    // CHANGE_SYSTEM convention: SUCCESS envelope carrying a Success=false payload on business failure,
    // so the caller can branch on the "Success" field. Use LinkedHashMap for conditional fields.
    public static ExtensionResponse changeResult(boolean success, String id, String errorMessage) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("Success", success);
        m.put("Id", id);
        if (!success) m.put("Error Message", errorMessage);
        return new ExtensionResponseBuilder().success(m).build();
    }
}
