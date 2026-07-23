// CatalogRequest snippets — copy one per operation into your Area class.
// Every request: unique id (localDomainRequest_<uuid>), typed @Field inputs (parameters),
// typed @Field output(s) (method-level), return ExtensionResponse (or List<Entity>/Map/File).
// Verbatim shapes from autotask, connect-wise, jira, restapi, salesforce, slack.

// ============================================================================================
// 1) QUERY_SYSTEM — read; entity-list output + count; text inputs
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Search Companies",
        description = "Search for companies by name",
        area = "Service Management",
        type = CatalogRequest.Type.QUERY_SYSTEM)
@Field.Desc(name = "Companies", type = "[ Entity(Company) ]", required = false)
@Field(name = "Count", type = "Number", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})
public ExtensionResponse searchCompanies(
        @Field.Text(name = "Company Name", required = true, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) String companyName,
        @Field.Text(name = "Search Type", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String searchType) {
    // TODO: business logic
    return new ExtensionResponseBuilder().success(new java.util.LinkedHashMap<>()).build();
}

// ============================================================================================
// 2) CHANGE_SYSTEM — create/update; scalar outputs; mixed inputs (text/paragraph/date/number)
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Create Ticket",
        description = "Create a new service ticket",
        area = "Service Management",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        tool = true)   // optional: expose as an AI-agent (MCP) tool. Requires krista-apis >= 1.0.125-sp1.
@Field.Boolean(name = "Success", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})
@Field.Text(name = "Ticket ID", required = false, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {})
public ExtensionResponse createTicket(
        @Field.Text(name = "Company ID", required = true, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) String companyId,
        @Field(name = "Description", type = "Paragraph", required = false, attributes = {@Attribute(name = "visualWidth", value = "L")}, options = {}) String description,
        @Field.Date(name = "Due Date Time", required = true, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) Long dueDateTime,
        @Field(name = "Max Results", type = "Number", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) Double maxResults) {
    // TODO: business logic
    return new ExtensionResponseBuilder().success(new java.util.LinkedHashMap<>()).build();
}

// ============================================================================================
// 3) CHANGE_SYSTEM — composite (key/value list) inputs; composite output; returns Map
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Post With Filter",
        description = "Send data with query parameters",
        area = "Write",
        type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field(name = "Response Info", type = "FreeForm", required = false, attributes = {}, options = {})
@Field.Desc(name = "Response", type = "[ Composite ]", required = false)
public Map<String, Object> postWithFilter(
        @Field(name = "URL", type = "Text", required = true, attributes = {}, options = {}) String url,
        @Field.Desc(name = "Payload", type = "{ key: Text, value: Text, file: File }", required = true) Map<String, Object> payload,
        @Field.Desc(name = "Query Parameters", type = "[ { key: Text, value: Text } ]", required = false) java.util.List<Map<String, Object>> queryParameters) {
    // TODO: business logic
    return new java.util.LinkedHashMap<>();
}

// ============================================================================================
// 4) CHANGE_SYSTEM — file input (@Field.File) + FreeForm output
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Add Attachment To Ticket",
        description = "Upload a file to a ticket",
        area = "Service Ticket",
        type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse addAttachmentToTicket(
        @Field.Text(name = "Ticket ID", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String ticketId,
        @Field.File(name = "File", required = true, attributes = {}, options = {}) app.krista.model.base.File file,
        @Field.Boolean(name = "Public Flag", required = false, attributes = {}, options = {}) Boolean publicFlag) {
    // TODO: business logic
    return new ExtensionResponseBuilder().success(new java.util.LinkedHashMap<>()).build();
}

// ============================================================================================
// 5) CHANGE_SYSTEM — file OUTPUT (returns app.krista.model.base.File)
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Get the file using download URL",
        description = "Download a file",
        area = "Download",
        type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.File(name = "File", multipleFileUpload = false, required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})
public app.krista.model.base.File getTheFileUsingDownloadURL(
        @Field.Text(name = "Download URL", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String downloadURL) {
    // TODO: business logic
    return null;
}

// ============================================================================================
// 6) CHANGE_SYSTEM — PickOne (dropdown) input; RichText input; list-of-Text input; FreeForm input
// ============================================================================================
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Update an issue",
        description = "Update fields on an issue",
        area = "Rituals",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        tool = true)
@Field.Desc(name = "Updated Issue", type = "Entity(Issue)")
public ExtensionResponse updateAnIssue(
        @Field.Text(name = "Issue Key", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String issueKey,
        @Field(name = "New Description", type = "RichText", required = false, attributes = {@Attribute(name = "toolTip", value = "'Rich text body'")}, options = {}) String newDescription,
        @Field.PickOne(name = "Comment Visibility", values = {"Public", "Internal"}, required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String commentVisibility,
        @Field.Desc(name = "Labels", type = "[ Text ]", required = false) java.util.List<String> labels,
        @Field(name = "Custom Fields", type = "FreeForm", required = false, attributes = {}, options = {}) app.krista.model.base.FreeForm customFields) {
    // TODO: business logic
    return new ExtensionResponseBuilder().success(new java.util.LinkedHashMap<>()).build();
}

// ============================================================================================
// 7) WAIT_FOR_EVENT — see WaitForEvent.snippet.java (eventName/eventData leading params).
// ============================================================================================
