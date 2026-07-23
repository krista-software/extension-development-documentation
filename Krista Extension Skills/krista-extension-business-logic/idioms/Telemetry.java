// IDIOM — telemetry lifecycle wrapper. Recording must NEVER crash business logic (swallow-all).
// Attributes must be LOW-CARDINALITY (operation name only; never IDs/emails/URLs).
package {{PACKAGE}}.catalog.extresp;

import app.krista.ksdk.telemetry.TelemetryMetrics;
import org.jvnet.hk2.annotations.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import java.util.HashMap;
import java.util.Map;

@Service
public class TelemetryHelper {

    private static final Logger LOG = LoggerFactory.getLogger(TelemetryHelper.class);
    private final TelemetryMetrics metrics;

    @Inject public TelemetryHelper(TelemetryMetrics metrics) { this.metrics = metrics; }

    /** {prefix} e.g. "github.ListReleases". Call at request start. */
    public long start(String prefix) {
        try { metrics.incrementCounter(prefix + ".requests", 1, Map.of()); } catch (Exception ignored) {}
        return System.currentTimeMillis();
    }

    public void recordSuccess(String prefix, long startTime, Map<String, String> tags) {
        try {
            long ms = System.currentTimeMillis() - startTime;
            Map<String, String> t = new HashMap<>(tags); t.put("status", "success");
            metrics.incrementCounter(prefix + ".success", 1, t);
            metrics.recordDuration(prefix + ".duration", ms, t);
        } catch (Exception ignored) { LOG.trace("telemetry success failed for {}", prefix); }
    }

    public void recordError(String prefix, long startTime, Exception ex, Map<String, String> tags) {
        try {
            long ms = System.currentTimeMillis() - startTime;
            Map<String, String> t = new HashMap<>(tags);
            t.put("status", "error");
            t.put("error_class", ex.getClass().getSimpleName());        // low-cardinality
            t.put("error_message", truncate(ex.getMessage(), 100));
            metrics.incrementCounter(prefix + ".failure", 1, t);
            metrics.recordDuration(prefix + ".duration", ms, t);
        } catch (Exception ignored) { LOG.trace("telemetry error failed for {}", prefix); }
    }

    private static String truncate(String s, int n) { return s == null ? "" : (s.length() > n ? s.substring(0, n) : s); }
}
