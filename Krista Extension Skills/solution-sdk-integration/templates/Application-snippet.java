// Step 3 — expose the SDK's JAX-RS resources. Pick ONE mode.
import com.krista.automation.ui.SolutionsTabProvider;
import org.jvnet.hk2.annotations.ContractsProvided;
import org.jvnet.hk2.annotations.Service;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;
import java.util.HashSet;
import java.util.Set;

// ===== MODE A — the extension has its OWN Application (recommended) =====
// Add the SDK resource classes alongside your own. Use tabEntry("{{APP_PATH}}") in customTabs().
@Service
@ApplicationPath("{{APP_PATH}}")            // must equal @Extension(jaxrsId=...) / the tab URL segment
@ContractsProvided(Application.class)
public class {{APP_CLASS}} extends Application {
    @Override
    public Set<Class<?>> getClasses() {
        Set<Class<?>> classes = new HashSet<>();
        // classes.add(MyExtensionResource.class);           // your own resources
        classes.addAll(SolutionsTabProvider.resourceClasses()); // + SDK resources
        return classes;
    }
}

// ===== MODE B — no existing Application: register the SDK's Application directly =====
// Return SolutionsTabProvider.application() from wherever you list application classes, and use the
// no-arg SolutionsTabProvider.tabEntry() in customTabs(). The SDK Application is @ApplicationPath("krista-automation").
//   Class<? extends Application> app = SolutionsTabProvider.application();
