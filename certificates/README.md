# Certificates for MongoDB

## DoD CA Certificates Installation

### Step 1: Download the PKI CA Certificate Bundles

- **Download**: Access the PKI CA Certificate Bundles from the [DoD PKI/PKE Document Library](https://public.cyber.mil/pki-pke/pkipke-document-library/).
  - **Direct link**: For PKCS#7 Bundle V5.13, download [here](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip).

```bash
curl -L https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -o dod_certificates.zip
```

### Step 2: Extract and Convert the Certificate

Unzip the file and follow the README for detailed instructions or use the following command to convert the certificates:

```bash
unzip dod_certificates.zip
openssl pkcs7 -in certificates_pkcs7_v5_13_dod/certificates_pkcs7_v5_13_dod_der.p7b -inform der -print_certs -out certificates_pkcs7_v5_13_dod/dod_CAs.pem
```

### Step 3: Place the Certificate

Move the extracted `dod_CAs.pem` file to the `certificates` folder.

```bash
mv certificates_pkcs7_v5_13_dod/dod_CAs.pem certificates/
```

The `dod_CAs.pem` file is what is required for the `net.tls.CAFile` option in the MongoDB configuration.

**Note:** The file gets automatically renamed to `CA_bundle.pem` when the Ansible playbook gets run.

```yaml
net:
	tls:
		mode: requireTLS
		CAFile: /etc/ssl/CA_bundle.pem
```

### Alternative Configuration: One-Command Setup

For a streamlined setup, you can execute all steps with a single command:

```bash
curl -L https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -o dod_certificates.zip && \
unzip dod_certificates.zip && \
openssl pkcs7 -in certificates_pkcs7_v5_13_dod/certificates_pkcs7_v5_13_dod_der.p7b -inform der -print_certs -out certificates_pkcs7_v5_13_dod/dod_CAs.pem && \
mv certificates_pkcs7_v5_13_dod/dod_CAs.pem certificates/
```

## MongoDB TLS/SSL Certificate and Key Generation

### Step 1: Generate a New Private Key

```bash
openssl genrsa -out mongodb-private.key 2048
```

This command generates a 2048-bit RSA private key, named `mongodb-private.key`, which is used for creating a CSR and signing the certificate.

### Step 2: Generate a Certificate Signing Request (CSR)

```bash
openssl req -new -key mongodb-private.key -out mongodb.csr
```

This command generates a CSR using the previously created private key. You'll specify the necessary details for the certificate, such as setting the `Common Name` to `localhost` for local testing.

### Step 3: Generate a Self-Signed Certificate

```bash
openssl x509 -req -days 397 -in mongodb.csr -signkey mongodb-private.key -out mongodb-cert.crt
```

This command creates a self-signed X.509 certificate using the CSR and the private key. The certificate is output as `mongodb-cert.crt`.

### Step 4: Combine Private Key and Certificate into One PEM File

```bash
cat mongodb-private.key mongodb-cert.crt > mongodb.pem
```

This command concatenates the private key and the certificate into a single file called `mongodb.pem`, which MongoDB requires for its `net.tls.certificateKeyFile` configuration.

This `mongodb.pem` file is what is being referenced in the MongoDB configuration:

```yaml
net:
	tls:
		mode: requireTLS
		certificateKeyFile: /etc/ssl/mongodb.pem
```

### Step 5: Append Certificate to Trusted CA Bundle and Move PEM File

```bash
mv mongodb.pem mongodb-cert.crt certificates/
cat mongodb-cert.crt >> dod_CAs.pem
```

Move the `mongodb.pem` and `mongodb-cert.crt` files to the `certificates` directory. Then, append the MongoDB certificate from `mongodb-cert.crt` to your list of trusted Certificate Authorities in `dod_CAs.pem`. This setup ensures that MongoDB utilizes the certificate for secure connections and that the system recognizes it as a trusted source.

### Alternative Configuration: One-Command Setup

For a streamlined setup, you can execute all steps with a single command:

```bash
openssl genrsa -out mongodb-private.key 2048 && \
openssl req -new -key mongodb-private.key -out mongodb.csr -subj '/C=US/ST=VA/L=McLean/O=MITRE/OU=MITRE SAF/CN=localhost' && \
openssl x509 -req -days 397 -in mongodb.csr -signkey mongodb-private.key -out mongodb-cert.crt && \
cat mongodb-private.key mongodb-cert.crt > mongodb.pem && \
mv mongodb.pem mongodb-cert.crt certificates/ && \
cat certificates/mongodb-cert.crt >> certificates/dod_CAs.pem
```
