# Certificates for MongoDB

## Table of Contents

1. [DoD CA Certificates Installation](#step-1-dod-ca-certificates-installation)
2. [Optional Step: Create a Local CA](#optional-step-2-create-a-local-ca-only-if-a-ca-does-not-exist)
3. [Generate and Sign the MongoDB Server Certificate](#step-3-generate-and-sign-the-mongodb-server-certificate-initial-setup-by-server-administrator-only)
4. [Generate and Sign User Certificates](#step-4-generate-and-sign-user-certificates-each-user)
5. [Configure MongoDB to Use the Local CA](#step-5-configure-mongodb-to-use-the-local-ca)
6. [Use the Certificates to Login to MongoDB](#step-6-use-the-certificates-to-login-to-mongodb)

**Note for Users**: If you only need to generate your own certificates, skip to [Step 4](#step-2-generate-and-sign-user-certificates-each-user) and follow the instructions there.

## Step 1: DoD CA Certificates Installation

1. **Download the PKI CA Certificate Bundles**

   - **Download**: Access the PKI CA Certificate Bundles from the [DoD PKI/PKE Document Library](https://public.cyber.mil/pki-pke/pkipke-document-library/).
     - **Direct link**: For PKCS#7 Bundle V5.13, download [here](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip).

   ```bash
   curl -L https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -o dod_certificates.zip
   ```

2. **Extract and Convert the Certificates**

   Unzip the file and follow the README for detailed instructions or use the following commands to unzip and convert the certificates:

   ```bash
   unzip dod_certificates.zip
   openssl pkcs7 -in certificates_pkcs7_v5_13_dod/certificates_pkcs7_v5_13_dod_der.p7b -inform der -print_certs -out certificates_pkcs7_v5_13_dod/dod_CAs.pem
   ```

3. **Place the Certificate**

   Move the extracted `dod_CAs.pem` file to the `certificates` folder.

   ```bash
   mv certificates_pkcs7_v5_13_dod/dod_CAs.pem certificates/
   ```

The `dod_CAs.pem` file is what is being referenced for the `net.tls.CAFile` option in the MongoDB configuration:

**Note:** The file gets automatically renamed to `CA_bundle.pem` when the Ansible playbook gets run.

```yaml
net:
  tls:
    mode: requireTLS
    CAFile: /etc/ssl/CA_bundle.pem
```

**Alternative Configuration: One-Command Setup**

For a streamlined setup, you can execute all steps with a single command:

```bash
curl -L https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -o dod_certificates.zip && \
unzip dod_certificates.zip && \
openssl pkcs7 -in certificates_pkcs7_v5_13_dod/certificates_pkcs7_v5_13_dod_der.p7b -inform der -print_certs -out certificates_pkcs7_v5_13_dod/dod_CAs.pem && \
mv certificates_pkcs7_v5_13_dod/dod_CAs.pem certificates/
```

## Optional Step 2: Create a Local CA (Only if a CA Does Not Exist)

All users trying to log in to the database will need this file.

1. **Generate the CA Private Key**:

   ```bash
   openssl genrsa -out localCA.key 2048
   ```

2. **Create the CA Certificate**:

   ```bash
   openssl req -x509 -new -nodes -key localCA.key -sha256 -days 3650 -out localCA.pem
   ```

## Step 3: Generate and Sign the MongoDB Server Certificate (Initial Setup by Server Administrator Only)

1. **Generate a New Private Key**

   ```bash
   openssl genrsa -out mongodb-private.key 2048
   ```

2. **Generate a Certificate Signing Request (CSR)**

   ```bash
   openssl req -new -key mongodb-private.key -out mongodb.csr
   ```

3. **Sign the MongoDB Server's CSR with the Local CA**

   ```bash
   openssl x509 -req -days 397 -sha256 -in mongodb.csr -CA localCA.pem -CAkey localCA.key -out mongodb-cert.crt
   ```

4. **Combine the MongoDB Server's Private Key and Certificate into One PEM File**

   ```bash
   cat mongodb-private.key mongodb-cert.crt > mongodb.pem
   ```

   This command concatenates the private key and the certificate into a single file called `mongodb.pem`.

   The `mongodb.pem` file is what is being referenced for the `net.tls.certificateKeyFile` option in the MongoDB configuration:

   ```yaml
   net:
     tls:
       mode: requireTLS
       certificateKeyFile: /etc/ssl/mongodb.pem
   ```

5. **Move PEM File**

   ```bash
   mv mongodb.pem certificates/
   ```

## Step 4: Generate and Sign User Certificates (Each User)

1. **Generate User’s Private Key**

   ```bash
   openssl genrsa -out user1.key 2048
   ```

2. **Create User’s CSR**

   ```bash
   openssl req -new -key user1.key -out user1.csr
   ```

3. **Sign User’s CSR with the Local CA**

   ```bash
   openssl x509 -req -days 397 -sha256 -in user1.csr -CA localCA.pem -CAkey localCA.key -out user1.crt
   ```

4. **Combine User’s Private Key and Certificate**

   ```bash
   cat user1.key user1.crt > user1.pem
   ```

## Step 5: Configure MongoDB to Use the Local CA

1. **Append Certificate to Trusted CA Bundle**

   ```bash
   mv localCA.pem certificates/
   cat certificates/localCA.pem >> certificates/dod_CAs.pem
   ```

## Step 6: Use the Certificates to Login to MongoDB

1. **Certificate Authority**

   This is the `tlsCAFile` flag

   The file that is used here is the CA pem file (e.g. `localCA.pem`)

2. **Client Certificate and Key**

   This is the `tlsCertificateKeyFile` flag

   The file that is used here is the user pem file (e.g. `user1.pem`)
