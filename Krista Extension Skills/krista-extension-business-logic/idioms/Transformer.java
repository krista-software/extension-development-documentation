// IDIOM — stateless DTO(JSON)->Entity transformer + reusable null-safe JSON accessors.
package {{PACKAGE}}.impl.transformers;

import com.google.gson.*;
import {{PACKAGE}}.catalog.entities.{{ENTITY_CLASS}};

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public final class {{ENTITY_CLASS}}Transformer {

    private {{ENTITY_CLASS}}Transformer() {}

    /** null-in -> null-out. Store IDs as String, timestamps as epoch-millis, use null-safe reads. */
    public static {{ENTITY_CLASS}} transform(JsonObject json) {
        if (json == null) return null;
        {{ENTITY_CLASS}} e = new {{ENTITY_CLASS}}();
        Long id = getLongOrNull(json, "id");
        e.id          = id != null ? String.valueOf(id) : null;   // Number entity fields are String
        e.name        = getStringOrNull(json, "name");
        e.description = getStringOrNull(json, "description");
        e.isPrivate   = getBoolOrNull(json, "private");
        e.author      = getNestedString(json, "author", "login");  // nested object
        e.createdAt   = getEpochMillisOrNull(json, "created_at");  // ISO-8601 -> epoch millis (Date field)
        e.labels      = joinStringArray(json, "labels");           // array -> comma-joined
        // business mapping lives here, e.g.: e.secretScanning = "enabled".equals(getNestedString(json,"security","secret_scanning"));
        return e;
    }

    /** never null; skips non-object elements. */
    public static List<{{ENTITY_CLASS}}> transformList(JsonArray array) {
        List<{{ENTITY_CLASS}}> out = new ArrayList<>();
        if (array == null) return out;
        for (JsonElement el : array) if (el.isJsonObject()) { var t = transform(el.getAsJsonObject()); if (t != null) out.add(t); }
        return out;
    }

    // ===== reusable null-safe accessors (put in a shared EntityHelperUtil, static-import everywhere) =====
    public static String getStringOrNull(JsonObject j, String k) {
        return (j == null || !j.has(k) || j.get(k).isJsonNull()) ? null : j.get(k).getAsString();
    }
    public static Long getLongOrNull(JsonObject j, String k) {
        return (j == null || !j.has(k) || j.get(k).isJsonNull()) ? null : j.get(k).getAsLong();
    }
    public static Boolean getBoolOrNull(JsonObject j, String k) {
        return (j == null || !j.has(k) || j.get(k).isJsonNull()) ? null : j.get(k).getAsBoolean();
    }
    public static String getNestedString(JsonObject j, String obj, String field) {
        if (j == null || !j.has(obj) || j.get(obj).isJsonNull()) return null;
        return getStringOrNull(j.getAsJsonObject(obj), field);
    }
    /** ISO-8601 -> epoch millis (String) for Krista @Field.Date; returns raw value if unparseable. */
    public static String getEpochMillisOrNull(JsonObject j, String k) {
        String raw = getStringOrNull(j, k);
        if (raw == null || raw.isBlank()) return null;
        try { return String.valueOf(Instant.parse(raw).toEpochMilli()); } catch (Exception e) { return raw; }
    }
    public static String joinStringArray(JsonObject j, String k) {
        if (j == null || !j.has(k) || j.get(k).isJsonNull()) return null;
        StringBuilder sb = new StringBuilder();
        for (JsonElement el : j.getAsJsonArray(k)) { if (sb.length() > 0) sb.append(", "); sb.append(el.getAsString()); }
        return sb.length() > 0 ? sb.toString() : null;
    }
}
