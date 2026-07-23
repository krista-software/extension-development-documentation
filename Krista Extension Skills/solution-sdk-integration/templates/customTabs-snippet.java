// Step 2 — add a "Solutions" tab in the extension's CUSTOM_TABS invoker, PRESERVING existing tabs.
// SolutionsTabProvider.tabEntry(appPath) yields: "Solutions" -> "rest/<appPath>/solutions/"

import com.krista.automation.ui.SolutionsTabProvider;
import app.krista.extension.impl.anno.InvokerRequest;
import java.util.LinkedHashMap;
import java.util.Map;

@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
public Map<String, String> customTabs() {
    Map<String, String> tabs = new LinkedHashMap<>();
    tabs.put("Documentation", "static/docs");           // keep your existing tabs

    // Mode A (extension has its own JAX-RS Application at @ApplicationPath("{{APP_PATH}}")):
    Map.Entry<String, String> solutions = SolutionsTabProvider.tabEntry("{{APP_PATH}}");
    tabs.put(solutions.getKey(), solutions.getValue());  // "Solutions" -> "rest/{{APP_PATH}}/solutions/"

    // Mode B (using the SDK's own Application, path "krista-automation"): use the no-arg form instead:
    // Map.Entry<String, String> solutions = SolutionsTabProvider.tabEntry();  // -> rest/krista-automation/solutions/

    return tabs;
}
