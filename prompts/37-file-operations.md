# Prompt 37: File Operations (Upload, Download, Share)

## Purpose

Implement file management catalog requests for cloud storage integrations. Covers upload (single and large file), download (as file and as link), folder operations, and sharing with permissions.

## Prerequisites

- Existing extension with API client for the storage provider
- EventHandler for async operations
- Understanding of the provider's file API (REST, SDK, or Graph)

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `OneDrive` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.onedrive` |
| Provider Name | `{{PROVIDER}}` | `OneDrive` / `Dropbox` / `Azure Files` |

---

## Prompt

```
I need you to implement file management catalog requests for my Krista {{PROVIDER}} extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Provider**: {{PROVIDER}}

## 1. File Upload Request

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Upload File",
    description = "Upload a file to the specified path",
    area = "Files",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.Desc(name = "Success", type = "Boolean", required = false)
@Field.Desc(name = "Message", type = "Text", required = false)
public ExtensionResponse uploadFile(
        @Field.File(name = "File", multipleFileUpload = false, required = true,
            attributes = {}, options = {}) File file,
        @Field.Text(name = "Destination Path", required = true,
            attributes = {@Attribute(name = "visualWidth", value = "L"),
                @Attribute(name = "toolTip", value = "'The folder path where the file will be uploaded'")},
            options = {}) String destinationPath,
        @Field.Boolean(name = "Overwrite If Exists", required = false,
            attributes = {@Attribute(name = "visualWidth", value = "S")},
            options = {}) Boolean overwrite) {

    try {
        // 1. Validate inputs
        String normalizedPath = PathUtils.normalize(destinationPath);
        if (file == null || file.getFileName() == null) {
            return errorResponse("File is required");
        }

        // 2. Upload via service layer
        UploadResult result = fileService.upload(file, normalizedPath, overwrite);

        // 3. Return success
        Map<String, Object> response = new HashMap<>();
        response.put("Success", true);
        response.put("Message", "Uploaded " + file.getFileName() + " to " + normalizedPath);
        return new ExtensionResponseBuilder().success(response).build();

    } catch (MustAuthorizeException e) {
        throw e;
    } catch (Exception e) {
        LOGGER.error("Upload failed: {}", e.getMessage());
        return errorResponse("Upload failed: " + e.getMessage());
    }
}
```

## 2. File Download Request

Two patterns: return the file directly, or return a download link.

### Download as File

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Download File",
    description = "Download a file by path or ID",
    area = "Files",
    type = CatalogRequest.Type.QUERY_SYSTEM, tool = true)
@Field.Desc(name = "Success", type = "Boolean", required = false)
@Field.File(name = "Downloaded File", required = false, attributes = {}, options = {})
public ExtensionResponse downloadFile(
        @Field.Text(name = "File Path", required = true,
            attributes = {@Attribute(name = "visualWidth", value = "L")},
            options = {}) String filePath) {

    try {
        File downloadedFile = fileService.download(PathUtils.normalize(filePath));

        Map<String, Object> response = new HashMap<>();
        response.put("Success", true);
        response.put("Downloaded File", downloadedFile);
        return new ExtensionResponseBuilder().success(response).build();

    } catch (MustAuthorizeException e) {
        throw e;
    } catch (Exception e) {
        return errorResponse("Download failed: " + e.getMessage());
    }
}
```

### Download as Link

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Get Download Link",
    description = "Get a shareable download link for a file",
    area = "Files",
    type = CatalogRequest.Type.QUERY_SYSTEM, tool = true)
@Field.Desc(name = "Download Link", type = "Text", required = false)
public ExtensionResponse getDownloadLink(
        @Field.Text(name = "File Path", required = true,
            attributes = {}, options = {}) String filePath) {

    String link = fileService.createShareLink(filePath);
    return ExtensionResponseFactory.create(Map.of("Download Link", link));
}
```

## 3. List Files in Folder

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "List Files",
    description = "List files in a folder with optional filtering",
    area = "Files",
    type = CatalogRequest.Type.QUERY_SYSTEM, tool = true)
@Field.Desc(name = "Files", type = "[ Entity(FileEntry) ]", required = false)
public ExtensionResponse listFiles(
        @Field.Text(name = "Folder Path", required = true,
            attributes = {@Attribute(name = "visualWidth", value = "L")},
            options = {}) String folderPath,
        @Field.Text(name = "File Extension Filter", required = false,
            attributes = {@Attribute(name = "toolTip", value = "'Filter by extension, e.g. .pdf, .xlsx'")},
            options = {}) String extensionFilter,
        @Field.Boolean(name = "Include Subfolders", required = false,
            attributes = {}, options = {}) Boolean recursive) {

    List<FileEntry> files = fileService.listFiles(
        PathUtils.normalize(folderPath),
        extensionFilter,
        Boolean.TRUE.equals(recursive));

    return ExtensionResponseFactory.create(Map.of("Files", files));
}
```

## 4. Create Folder

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Create Folder",
    description = "Create a new folder at the specified path",
    area = "Files",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.Desc(name = "Success", type = "Boolean", required = false)
public ExtensionResponse createFolder(
        @Field.Text(name = "Folder Path", required = true,
            attributes = {@Attribute(name = "visualWidth", value = "L")},
            options = {}) String folderPath) {

    fileService.createFolder(PathUtils.normalize(folderPath));
    return new ExtensionResponseBuilder()
        .success(Map.of("Success", true))
        .build();
}
```

## 5. Path Normalization Utility

```java
package {{PACKAGE_NAME}}.util;

public class PathUtils {
    public static String normalize(String path) {
        if (path == null) return "";
        return path.trim()
            .replace("\\", "/")       // Backslash to forward slash
            .replaceAll("^/+", "")    // Remove leading slashes
            .replaceAll("/+$", "");   // Remove trailing slashes
    }

    public static String join(String basePath, String fileName) {
        String normalized = normalize(basePath);
        return normalized.isEmpty() ? fileName : normalized + "/" + fileName;
    }

    public static boolean isValid(String path) {
        return path != null && !path.trim().isEmpty();
    }
}
```

## 6. FileEntry Entity

```java
@Domain(...)
@Entity(name = "FileEntry", id = "localDomainEntity_{{UUID}}",
    primaryKey = "File ID", supportStore = false, options = {})
public class FileEntry {
    @Field.Text(name = "File ID", required = false, attributes = {}, options = {})
    @Searchable
    public String fileId;

    @Field.Text(name = "Name", required = false, attributes = {}, options = {})
    @Searchable @ToString
    public String name;

    @Field.Text(name = "Path", required = false, attributes = {}, options = {})
    public String path;

    @Field(name = "Size", type = "Number", required = false, attributes = {}, options = {})
    public Long size;

    @Field.Text(name = "Modified", required = false, attributes = {}, options = {})
    public String lastModified;
}
```

## Best Practices

1. **Always normalize paths** — handle backslashes, leading/trailing slashes, whitespace
2. **Validate file size before upload** — check against provider limits
3. **Use temp files for downloads** — clean up in finally blocks
4. **Mark read-only operations as `tool = true`** — enables MCP agent access
5. **Handle MustAuthorizeException** — always rethrow for OAuth/MCP flows
6. **Log operation outcomes, not file content** — avoid logging file names with sensitive data
7. **Support both path and ID access** — some providers use IDs (Dropbox), others use paths (Azure)

## Related Prompts

- [Prompt 33: Delta Sync](33-delta-sync-change-detection.md) — detect file changes
- [Prompt 32: Async Catalog Request](32-async-catalog-request.md) — for large file batch operations
- [Prompt 24: Entity Development](24-entity-development.md) — for FileEntry entity
```
