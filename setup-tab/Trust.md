<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Trust

# Trust

## Overview

Some integrations require additional **trust configuration** to connect securely over TLS/SSL, especially when:

- the target uses a private CA,
- the target uses a self-signed certificate,
- mutual TLS (mTLS) is required.

This page describes what you should capture and validate in the Setup tab when your extension needs custom trust material.

## Step-by-step: add trust configuration support

1. **Identify the trust requirement**:
   - custom CA / private PKI
   - self-signed cert
   - mutual TLS (mTLS)
2. **Add Setup tab fields** for trust material (trust store / key store + passwords).
3. **Validate the trust material** during setup-time validation (load keystores, check expiry).
4. **Build an `SSLContext`** at runtime and attach it to your HTTP client.
5. **Document rotation**: how operators update certificates and re-save the invoker.

## When you need trust configuration

You typically need trust configuration when outbound HTTPS calls fail with certificate errors (for example: unknown CA, hostname mismatch, expired cert).

If your integration uses public, well-known CAs and standard HTTPS, you usually do not need custom trust settings.

## What to capture in the Setup tab

Common configuration fields:

- **Trust store / CA bundle** (file or encoded text)
- **Key store** (for mTLS client certificates)
- **Key/trust store password** (secured)
- **TLS verification mode** (pick-one; avoid “disable verification” unless strictly necessary)

Guidance:

- Store passwords as **secured** attributes.
- Prefer standard formats such as **PKCS12**.
- Validate that the provided material parses and that the certificate is not expired.

### Example: building an `SSLContext` from PKCS12

From the monolithic guide (kristagrand `MixSSL` pattern):

```java
public static SSLContext createSSLContext(byte[] certBytes, char[] password) throws Exception {
    final KeyStore ks = KeyStore.getInstance("PKCS12");
    ks.load(new ByteArrayInputStream(certBytes), password);

    final KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
    kmf.init(ks, password);

    final TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);

    final SSLContext sslContext = SSLContext.getInstance("TLS");
    sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
    return sslContext;
}
```

### Example: trust store configuration (server-side)

If you manage TLS assets via configuration, a common shape looks like:

```json
{
  "ssl": {
    "enabled": true,
    "port": 8443,
    "keyStore": {
      "type": "PKCS12",
      "path": "/opt/krista/certs/server.p12",
      "password": "${SSL_KEYSTORE_PASSWORD}"
    },
    "trustStore": {
      "type": "PKCS12",
      "path": "/opt/krista/certs/truststore.p12",
      "password": "${SSL_TRUSTSTORE_PASSWORD}"
    }
  }
}
```

## Validation ideas

Good setup-time checks include:

1. certificate/key store can be loaded with the provided password
2. certificate chain is present (when required)
3. expiry dates are in the future
4. optional: perform a fast HTTPS handshake to the configured host

See: [Validation and troubleshooting](ValidationAndTroubleshooting.md)

### Certificate loading pattern

```java
public SSLContext buildSslContext(String certPath, String password) throws Exception {
    byte[] certBytes = Files.readAllBytes(Paths.get(certPath));
    return createSSLContext(certBytes, password.toCharArray());
}
```

### Custom trust manager (advanced)

If you need custom validation rules, you can wrap the default trust manager and fall back to a custom trust store.

```java
public class CustomTrustManager implements X509TrustManager {
    private final X509TrustManager defaultTrustManager;

    public CustomTrustManager() throws Exception {
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init((KeyStore) null);
        this.defaultTrustManager = (X509TrustManager) tmf.getTrustManagers()[0];
    }

    @Override
    public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
        defaultTrustManager.checkServerTrusted(chain, authType);
    }

    @Override
    public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
        defaultTrustManager.checkClientTrusted(chain, authType);
    }

    @Override
    public X509Certificate[] getAcceptedIssuers() {
        return defaultTrustManager.getAcceptedIssuers();
    }
}
```

## Security best practices

1. **Keep TLS verification enabled** and use hostname verification.
2. Do not log certificate contents or passwords.
3. Plan for certificate rotation (document how to update the invoker configuration).

Additional recommendations (from the monolithic guide):

4. **Use TLS 1.2+**.
5. **Monitor certificate expiry** and rotate before expiration.
6. **Never hardcode passwords**; store them as secured values.

## How this maps to Krista invoker lifecycle

Trust configuration becomes meaningful only after configuration is saved and your extension can build runtime TLS resources.

1. **Before Save**: users provide trust material (trust store / key store and passwords) in the Setup tab.
2. **On Save**: validate the trust inputs in `@InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)`:
   - keystore/truststore parses,
   - password works,
   - certificates are not expired,
   - optional: a fast handshake/test call.
3. **After Save**:
   - **`INVOKER_LOADED`**: build an `SSLContext` (or HTTP client configured with custom trust) from saved attributes.
   - **`INVOKER_UPDATED`**: rebuild the `SSLContext`/client when certs or passwords rotate; ensure old clients are closed.
   - **`INVOKER_UNLOADED`**: shutdown and cleanup any clients/pools.

See:

- [Invoker requests (`@InvokerRequest`)](../reference/InvokerRequests.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Save changes](SaveChanges.md)

## Troubleshooting

- **Unknown CA**: provide a CA bundle/trust store that includes the issuer.
- **Expired certificate**: rotate the certificate and re-save the invoker.
- **Hostname mismatch**: confirm the base URL host matches the certificate SAN/CN.

If you see intermittent TLS failures, check:

- multiple load-balanced endpoints with different certificates
- intermediate CA chain missing on the server
- clock skew affecting notBefore/notAfter validation

## Next steps

- Configure credentials: [Authentication](Authentication.md)
- Understand persistence behavior: [Save changes](SaveChanges.md)




## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
