# Certificates

## DoD Certificate Authority Certificates Installation

### Obtain Certificates

- **Download**: Access the PKI CA Certificate Bundles from the [DoD PKI/PKE Document Library](https://public.cyber.mil/pki-pke/pkipke-document-library/).
  - **Direct link**: For PKCS#7 Bundle V5.13, download [here](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip).

### Installation

1.  **Extract Package**: Unzip the downloaded file and follow the README for usage instructions
2.  **Place Certificates**: Move the certificate to the `certificates` folder.

## Steps to Correctly Generate a Certificate and Key for MongoDB TLS/SSL:

### 1. Generate a New Private Key

```bash
openssl genrsa -out mongodb-private.key 2048
```

This command creates a 2048-bit RSA private key.

### 2. Generate a Certificate Signing Request (CSR)

```bash
openssl req -new -key mongodb-private.key -out mongodb.csr
```

You'll be prompted to enter details for the certificate; fill these out as they pertain to your organization or for testing purposes.

### 3. Generate a Self-Signed Certificate

If you're setting this up for testing purposes or internal use, you can generate a self-signed certificate:

```bash
openssl x509 -req -days 365 -in mongodb.csr -signkey mongodb-private.key -out mongodb-cert.pem
```

This creates a certificate that's valid for 365 days.

### 4. Combine Private Key and Certificate into One PEM File

MongoDB expects the private key and the certificate to be in the same PEM file for `net.tls.certificateKeyFile`:

```bash
cat mongodb-private.key mongodb-cert.pem > mongodb.pem
```

This `mongodb.pem` file is what you should reference in your MongoDB configuration:

```yaml
net:
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb.pem
```
