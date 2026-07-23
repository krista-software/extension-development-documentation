# File handling — Krista media files (`KristaMediaClient` / `FileRepository`)

Krista represents files as **`app.krista.model.base.File`** (a media reference: `mediaId`, `fileName`),
not raw bytes. External APIs work in bytes / `java.io.File`. The bridge between the two is the platform
**`app.krista.ksdk.files.FileRepository`** — and the reusable wrapper around it is **`KristaMediaClient`**
(idiom: `idioms/KristaMediaClient.java`, from the outlook-4 extension).

## When to use it — the detection trigger

Reach for `KristaMediaClient` **whenever a catalog request moves a binary file** in either direction:

| The request… | Field shape | Use |
|---|---|---|
| **takes a file input** (attach, upload, import) | parameter `@Field.File(...) app.krista.model.base.File file` | `toJavaFile(file)` → local `java.io.File` → send its bytes to the external API |
| **returns a file output** (download, export, get-as-file) | method-level `@Field.File(...)` output, returns `app.krista.model.base.File` | fetch bytes from the API into a `java.io.File` → `toKristaFile(localFile)` → return the Krista File |

Signals in the spec that you need it: endpoints named `upload`, `download`, `attachment`, `export`,
`content`, `asset`, `import`, or that produce/consume `application/octet-stream` / `multipart/form-data`
/ a binary body. If a request only passes text/JSON, you do **not** need it.

## The API (what the wrapper gives you)

```java
@Inject FileRepository fileRepository;   // platform service — injected

// upload: java.io.File  ->  Krista File (for a @Field.File OUTPUT)
app.krista.model.base.File toKristaFile(java.io.File f)     // sanitizes name; zips blacklisted extensions
app.krista.model.base.File uploadDirect(java.io.File f)    // preserve extension as-is (no blacklist/zip)
app.krista.model.base.File toKristaZipFile(java.io.File f) // always zip then upload

// download: Krista File  ->  java.io.File (for a @Field.File INPUT)
java.io.File toJavaFile(app.krista.model.base.File kfile)
```

Under the hood: `fileRepository.createNewFileByName(name)` → `FileHandle.setContent(stream)` →
`handle.getFile()` for upload; `fileRepository.getFile(kfile)` → `FileHandle.getContent()` for download.
It also consults `fileRepository.getBlackListedFileExtensions()` and zips anything Krista won't accept.

## Wiring

- `KristaMediaClient` is an HK2 `@Service` that `@Inject`s `FileRepository`. Inject the client into the
  Area/service that handles the file request (constructor `@Inject`), exactly like the HTTP client.
- Keep it out of the transformer/validation layers — file movement is an integration concern.

## Rules / gotchas (from the real code)

- **Sanitize filenames** before upload (the client does this via a `FilenameUtil.toSafeFilename`).
- **Blacklisted extensions** are auto-zipped by `toKristaFile` — if the extension must be preserved
  (e.g. serving MIME text as `.txt`), use `uploadDirect` instead.
- Downloaded/temp files land under `/tmp`; clean up if you write many.
- Wrap calls in the same error handling as HTTP (`IOException` → SYSTEM_ERROR in the audited wrapper).
- Don't log file contents; filenames/`mediaId` at DEBUG are fine.

## Example (file-output request)

```java
@CatalogRequest(id = "localDomainRequest_<uuid>", name = "Download Release Asset",
        area = "Release Management", type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.File(name = "File", multipleFileUpload = false, required = false, attributes = {}, options = {})
public app.krista.model.base.File downloadReleaseAsset(
        @Field.Text(name = "Asset URL", required = true, attributes = {}, options = {}) String assetUrl) {
    java.io.File local = client.downloadToTempFile(assetUrl);   // your HTTP client streams bytes to a temp file
    return mediaClient.toKristaFile(local);                     // hand Krista a File reference
}
```

And a file-input request calls `mediaClient.toJavaFile(file)` first, then uploads the bytes.
