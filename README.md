# MongoDB Container Hardening Workflow

A workflow for hardening a MongoDB container against a STIG using Packer and Ansible, including a scanning step and a threshold validation step to verify compliance.

## Dependencies

- [Docker](https://docs.docker.com/engine/install/) - Container engine.
- [Packer](https://developer.hashicorp.com/packer/install) - A container image builder tool.
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) - An orchestration tool that can target containers. Used as the provisioner to STIG-harden the container under Packer's direction.
- Progress Chef's [InSpec](https://docs.chef.io/inspec/install/) testing framework.
- [SAF CLI](https://saf-cli.mitre.org) for validating the results of the InSpec scan against a defined threshold (e.g. "95% of tests pass", or "no high-severity failures")

## Tailoring Your Scan to Your Environment

To ensure the profile runs correctly in your specific environment, you need to configure the inputs the `inspec.yml` and the `inputs.yml` file. A template file named `inputs_template.yml` is provided to help you get started. More information about InSpec inputs can be found in the [InSpec Profile Documentation](https://docs.chef.io/inspec/profiles/).

### Verify Ansible Variables

Ensure that the Ansible variables are correctly set under `spec/ansible/roles/mongo-stig/defaults/main.yml`

### Example `inputs.yml`

```yaml
# The username for the MongoDB administrative account.
mongo_dba: "root"

# The password for the MongoDB administrative account.
mongo_dba_password: "root"

# The hostname or IP address of the MongoDB server.
mongo_host: "localhost"

# The port number on which the MongoDB server is listening.
mongo_port: "27017"

# The database to authenticate against.
mongo_auth_source: "admin"

# The path to the Certificate Authority (CA) bundle file for SSL/TLS connections.
ca_file: "/etc/ssl/CA_bundle.pem"

# The path to the MongoDB SSL/TLS certificate key file.
certificate_key_file: "/etc/ssl/mongodb.pem"
```

## Usage

1. **Clone the Repository**

   Start by cloning the `mongo-hardening` repository from GitHub to your local machine:

   ```sh
   git clone https://github.com/mitre/mongodb-enterprise-advanced-4-stig-baseline-hardening.git
   cd mongo-hardening
   ```

2. **Create MongoDB Certificates**

   Follow the `README.md` under the `certificates` directory to download the DoD Certificates PKI Bundle and to create any other necessary certificates.

3. **Update `main.yml` for the Ansible Playbook**

   Update the `main.yml` file located at `spec/ansible/roles/mongo-stig/defaults/main.yml` with your values.

4. **Create and Update `inputs.yml` for Inspec**

   Execute the following command to create the `inputs.yml` file under `spec/mongo-inspec-profile` by copying `inputs_template.yml` and renaming it to `inputs.yml`.
   Update this file with your values.

   ```sh
   cp spec/mongo-inspec-profile/inputs_template.yml spec/mongo-inspec-profile/inputs.yml
   ```

5. **Update `inspec.yml` for InSpec**

   Update the `inspec.yml` file located at `spec/mongo-inspec-profile/inspec.yml` with your values.
   Most values should remain unchanged; only modify them if you are certain about the changes to avoid causing issues with the Ansible playbook execution.

6. **Check Configuration Flags**

   If you want to disable the `fips_mode` or `enterprise_edition` flags, ensure they are disabled in both `spec/ansible/mongo-stig-hardening-playbook.yml` and `spec/ansible/roles/mongo-stig/defaults/main.yml`.

7. **Initialize Packer**

   Initialize Packer to install the required Ansible and Docker plugins:

   ```sh
   packer init .
   ```

8. **Build the Hardened Image**

   Execute the following command to build, test, and save the hardened Mongo image:

   ```sh
   packer build mongo-hardening.pkr.hcl
   ```

9. **Run the Hardened Image**

   Execute the following command to run the hardened Mongo image:

   ```sh
   docker run -d \
      --name mongo-hardened \
      -p 27017:27017 \
      -v mongodb_configdb:/data/configdb \
      -v mongodb_db:/data/db \
      -e PATH="/usr/local/src/openssl-3.1.0/apps:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
      -e LD_LIBRARY_PATH="/usr/local/src/openssl-3.1.0:" \
      mongo-hardened \
      mongod --config /etc/mongod.conf
   ```

## Notes

### InSpec

Full repository [here](https://github.com/mitre/mongodb-enterprise-advanced-4-stig-baseline).

- Running InSpec Checks

  - Remove the `--controls` flag to run all inspec checks at once.

  ```sh
  inspec exec spec/mongo-inspec-profile/ -t docker://mongo-hardened --controls=SV-252134 --input-file=spec/mongo-inspec-profile/inputs.yml --reporter cli json:reports/inspec_results.json --no-create-lockfile --show-progress
  ```

- Deeper Testing with InSpec Shell

  ```sh
  inspec shell -t docker://mongo-hardened --depends=spec/mongo-inspec-profile/ --input-file=spec/mongo-inspec-profile/inputs.yml
  ```

- You can add additional types of scanning beyond InSpec (or get InSpec to run more than one testing profile) by modifying the `scripts/scan.sh` file. See the [MITRE SAF(c) Validation Library] (https://saf.mitre.org/#/validate) for more InSpec profiles, or use your favorite image scanning tool.

### Certificates

For the full `README`, refer to the `certificates` folder.

- If you encounter connection errors, ensure you have the latest OpenSSL version (last tested with OpenSSL 3.3.0).

## Authors

- Sean Chacon Cai - [seanlongcc](https://github.com/seanlongcc)

## Special Thanks

- Will Dower - [wdower](https://github.com/wdower)
