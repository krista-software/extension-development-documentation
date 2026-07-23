// IDIOM — two-tier input validation: a static toolkit + a per-entity @Service.
// Every failure throws IllegalArgumentException with FIELD + WHY + EXAMPLE. That exception is the
// signal the orchestration layer catches to produce an INPUT-classified / validation response.
package {{PACKAGE}}.service.validation;

import org.jvnet.hk2.annotations.Service;

// ===== Tier 1: static primitive toolkit (non-instantiable) =====
final class ValidationUtil {
    private ValidationUtil() {}

    static boolean isNullOrEmpty(String v) { return v == null || v.trim().isEmpty(); }

    static void requireNonEmpty(String value, String field) {
        if (isNullOrEmpty(value))
            throw new IllegalArgumentException(field + " is required. Please provide a value for " + field + ".");
    }
    static void requireNonNull(Object value, String field) {
        if (value == null) throw new IllegalArgumentException(field + " is required.");
    }
    static void requireAtLeastOne(String[] names, String... values) {
        for (String v : values) if (!isNullOrEmpty(v)) return;
        throw new IllegalArgumentException("At least one of the following is required: " + String.join(", ", names) + ".");
    }
    static Long parseLongOrNull(String value) {
        if (isNullOrEmpty(value)) return null;
        try { return Long.parseLong(value.trim()); }
        catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid number '" + value + "'. Provide a valid numeric value. Examples: 123, 456789.");
        }
    }
}

// ===== Tier 2: domain validation service (compose primitives; parse-and-validate once) =====
@Service
public class {{ENTITY_CLASS}}ValidationService {

    public void validateCreate(String companyId, String title, String description) {
        ValidationUtil.requireNonEmpty(companyId, "Company ID");
        ValidationUtil.requireNonEmpty(title, "Title");
        ValidationUtil.requireNonEmpty(description, "Description");
    }

    public void validateSearchCriteria(String companyId, String status) {
        ValidationUtil.requireAtLeastOne(new String[]{"Company ID", "Status"}, companyId, status);
    }

    /** parse-and-validate an ID string once; the typed value is the validation result. */
    public Long validateId(String id, String field) {
        ValidationUtil.requireNonEmpty(id, field);
        Long v = ValidationUtil.parseLongOrNull(id);
        ValidationUtil.requireNonNull(v, field);
        return v;
    }
}
