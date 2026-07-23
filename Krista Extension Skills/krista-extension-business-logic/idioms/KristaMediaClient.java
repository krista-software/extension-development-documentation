// IDIOM — bridge between java.io.File and Krista's app.krista.model.base.File (media store).
// Use in any catalog request that UPLOADS a file input or RETURNS a file output. Faithful to the
// outlook-4 implementation; adapt {{PACKAGE}} and the FilenameUtil helper.
package {{PACKAGE}}.integration;

import app.krista.ksdk.files.FileHandle;
import app.krista.ksdk.files.FileRepository;
import org.jvnet.hk2.annotations.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class KristaMediaClient {

    private static final Logger LOG = LoggerFactory.getLogger(KristaMediaClient.class);
    private static final String TMP = "/tmp/";
    private static final int BUF = 4096;

    @Inject
    private FileRepository fileRepository;   // platform service

    /** Krista File INPUT -> local java.io.File (so you can send its bytes to the external API). */
    public File toJavaFile(app.krista.model.base.File kfile) throws IOException {
        try (FileHandle handle = fileRepository.getFile(kfile)) {
            File out = new File(safeName(kfile.getFileName()));
            try (OutputStream os = new BufferedOutputStream(new FileOutputStream(out));
                 InputStream in = handle.getContent()) {
                byte[] b = new byte[BUF]; int n;
                while ((n = in.read(b)) != -1) os.write(b, 0, n);
            }
            return out;
        }
    }

    /** local java.io.File -> Krista File OUTPUT. Sanitizes name; zips blacklisted extensions. */
    public app.krista.model.base.File toKristaFile(File file) throws IOException {
        File f = sanitizeAndCopy(file);
        if (isBlacklisted(f.getName())) {
            String zip = TMP + baseName(f.getName()) + ".zip";
            compress(zip, f.getAbsolutePath());
            f = new File(zip);
        }
        return upload(f);
    }

    /** Upload preserving the extension as-is (bypass blacklist/zip) — e.g. serving MIME text as .txt. */
    public app.krista.model.base.File uploadDirect(File file) throws IOException {
        return upload(sanitizeAndCopy(file));
    }

    /** Always zip then upload. */
    public app.krista.model.base.File toKristaZipFile(File file) throws IOException {
        File f = sanitizeAndCopy(file);
        String zip = TMP + baseName(f.getName()) + ".zip";
        compress(zip, f.getAbsolutePath());
        return upload(new File(zip));
    }

    // ---- internals ----
    private app.krista.model.base.File upload(File file) throws IOException {
        try (FileHandle handle = fileRepository.createNewFileByName(file.getName())) {
            if (handle == null) throw new IOException("Null file handle for: " + file.getName());
            try (FileInputStream in = new FileInputStream(file)) {
                handle.setContent(in);
            }
            app.krista.model.base.File result = handle.getFile();
            if (result == null) throw new IOException("Null Krista File after upload: " + file.getName());
            LOG.debug("Uploaded {} -> mediaId {}", result.getFileName(), result.getMediaId());
            return result;
        }
    }

    private boolean isBlacklisted(String name) {
        int dot = name.lastIndexOf('.');
        if (dot < 0) return false;
        Set<String> black = fileRepository.getBlackListedFileExtensions();
        return black != null && black.contains(name.substring(dot + 1));
    }

    private File sanitizeAndCopy(File file) throws IOException {
        String safe = safeName(file.getName());
        if (safe.equals(file.getName())) return file;
        String parent = file.getParent() != null ? file.getParent() : TMP;
        File dst = new File(parent + "/" + safe);
        Files.copy(file.toPath(), dst.toPath(), StandardCopyOption.REPLACE_EXISTING);
        return dst;
    }

    private static void compress(String zipPath, String srcPath) throws IOException {
        File src = new File(srcPath);
        try (ZipOutputStream zip = new ZipOutputStream(new FileOutputStream(zipPath));
             FileInputStream in = new FileInputStream(src)) {
            zip.putNextEntry(new ZipEntry(src.getName()));
            byte[] b = new byte[1024]; int n;
            while ((n = in.read(b)) >= 0) zip.write(b, 0, n);
            zip.closeEntry();
        }
    }

    private static String baseName(String name) {
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    // Replace problematic chars with '_'. In outlook-4 this is FilenameUtil.toSafeFilename(name).
    private static String safeName(String name) {
        return name == null ? "file" : name.replaceAll("[^A-Za-z0-9._-]", "_");
    }
}
