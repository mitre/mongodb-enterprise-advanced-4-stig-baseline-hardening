report = {
  "report_to_heimdall" = true
  "heimdall_url"       = "https://heimdall-demo.mitre.org/evaluations"
  "heimdall_api_key"   = "your_actual_api_key_here"
}

attestation = {
  "report_dir"                  = "reports",
  "inspec_report_filename"      = "mongo_inspec_results.json",
  "attestation_filename"        = "attestation_template.json"
  "attested_inspec_filename"    = "mongo_inspec_results_attested.json"
}

mongo = {
  "container_name"         = "mongo-hardened"
  "mongo_dba"              = "root"
  "mongo_dba_password"     = "root"
  "mongo_host"             = "localhost"
  "mongo_port"             = "27017"
  "ca_file"                = "/etc/ssl/CA_bundle.pem"
  "certificate_key_file"   = "/etc/ssl/mongodb.pem"
  "auth_mechanism"         = "SCRAM-SHA-256"
}
