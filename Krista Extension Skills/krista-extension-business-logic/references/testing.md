# Testing the business logic

The layering makes each unit testable in isolation — the mature extensions ship a `*Test` per infra
class. Target:

- **Connector**: depend on `IHttpClient`; test the real client against okhttp **`mockwebserver`**
  (`com.squareup.okhttp3:mockwebserver`) — assert the request path/headers/body and that each HTTP
  status maps to the right exception. Test the 204/no-content paths.
- **Transformers**: pure functions — feed representative `JsonObject`s (including nulls, missing keys,
  malformed elements) and assert the entity fields, coercions (epoch-millis, ID→String), and that
  `transformList` skips non-objects and never returns null.
- **Validation**: assert each rule throws `IllegalArgumentException` with an actionable message, and
  that parse-and-validate returns the typed value for good input.
- **Operations/Area**: mock the connector + validation + response builders; assert the try/catch maps
  a validation error to a validation response and other exceptions to a failure response, and that
  telemetry start/success/failure is invoked.
- **Response building**: assert stable keys and the `CHANGE_SYSTEM` `Success=false` envelope shape.

Test deps (already in the scaffolding build.gradle): JUnit 5 (`junit-jupiter`), Mockito
(`mockito-core` + `mockito-junit-jupiter`), and `mockwebserver`.
