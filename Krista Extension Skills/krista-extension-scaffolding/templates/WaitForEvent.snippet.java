// WAIT_FOR_EVENT catalog request — the event-trigger contract.
//
// A WAIT_FOR_EVENT request is fired by an inbound event delivered through EventHandler.handleEvent
// (see templates/webhook/). Its first TWO parameters are the fixed framework contract:
//     @Field(name = "eventName", type = "Text")     String   eventName
//     @Field(name = "eventData", type = "FreeForm") FreeForm eventData
// followed by your own configuration/filter fields. The body matches eventName + filters against the
// delivered eventData; if it matches, return the shaped output; if not, throw to decline the event.

// --- Variant A: structured (map/composite) output, returns ExtensionResponse ---
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Get Ticket Status Notification",
        description = "Triggers when a ticket status changes",
        area = "Service Ticket",
        type = CatalogRequest.Type.WAIT_FOR_EVENT)
@Field.Desc(name = "Ticket Details",
        type = "{ Id: Text, Summary: Text, Status: Text, Company: Text }", required = true)
public ExtensionResponse getTicketStatusNotification(
        @Field(name = "eventName", type = "Text") String eventName,
        @Field(name = "eventData", type = "FreeForm") app.krista.model.base.FreeForm eventData,
        @Field.Text(name = "Triggered On Status Name", required = true,
                attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) String statusName) {
    // TODO: business logic — parse eventData, match on statusName, build output or throw to decline.
    return new ExtensionResponseBuilder().success(new java.util.LinkedHashMap<>()).build();
}

// --- Variant B: entity-list output ---
@CatalogRequest(
        id = "localDomainRequest_<uuid>",
        name = "Slack Event In Map",
        description = "Triggers on an inbound Slack event for a channel",
        area = "SlackAPI",
        type = CatalogRequest.Type.WAIT_FOR_EVENT)
@Field(name = "Event Response", type = "FreeForm", required = false, attributes = {}, options = {})
public app.krista.model.base.FreeForm slackEventInMap(
        @Field(name = "eventName", type = "Text") String eventName,
        @Field(name = "eventData", type = "FreeForm") app.krista.model.base.FreeForm eventData,
        @Field.Text(name = "Channel Name", required = true,
                attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String channelName) {
    // TODO: business logic
    return eventData;
}
