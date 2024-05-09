control 'SV-252154' do
  title 'Database objects (including but not limited to tables, indexes, storage, stored procedures, functions, triggers, links to software external to MongoDB, etc.) must be owned by database/DBMS principals authorized for ownership.'
  desc "Within the database, object ownership implies full privileges to the owned object, including the privilege to assign access to the owned objects to other subjects. Database functions and procedures can be coded using definer's rights. This allows anyone who utilizes the object to perform the actions if they were the owner. If not properly managed, this can lead to privileged actions being taken by unauthorized individuals.

Conversely, if critical tables or other objects rely on unauthorized owner accounts, these objects may be lost when an account is removed."
  desc 'check', 'Run the following command to get the roles from a MongoDB database.

For each database in MongoDB:

use database
db.getUsers()

If the output shows a role of "dbOwner", this is a finding.'
  desc 'fix', 'For each user where the role of dbOwner is found verify whether or not the user is authorized for this role on the resources listed.

This information will be found in the organizational or site-specific documentation.

If a user if found not authorized to have the role dbOwner the remove that role from the user with the
db.revokeRolesFromUser() command

https://docs.mongodb.com/v4.4/reference/command/revokeRolesFromUser/'
  impact 0.5
  ref 'DPMS Target MongoDB Enterprise Advanced 4.x'
  tag check_id: 'C-55610r813842_chk'
  tag severity: 'medium'
  tag gid: 'V-252154'
  tag rid: 'SV-252154r813844_rule'
  tag stig_id: 'MD4X-00-002300'
  tag gtitle: 'SRG-APP-000133-DB-000200'
  tag fix_id: 'F-55560r813843_fix'
  tag 'documentable'
  tag cci: ['CCI-001499']
  tag nist: ['CM-5 (6)']

  get_users = 'EJSON.stringify(db.getUsers())'

  get_dbs = "EJSON.stringify(db.adminCommand('listDatabases'))"

  run_get_dbs = "mongosh \"mongodb://#{input('mongo_dba')}:#{input('mongo_dba_password')}@#{input('mongo_host')}:#{input('mongo_port')}/?authSource=#{input 'mongo_auth_source'}&tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{get_dbs}\""

  dbs_output = json({ command: run_get_dbs }).params

  # extract just the names of the databases
  db_names = dbs_output['databases'].map { |db| db['name'] }

  db_names.each do |db_name|
    run_get_users = "mongosh \"mongodb://#{input('mongo_dba')}:#{input('mongo_dba_password')}@#{input('mongo_host')}:#{input('mongo_port')}/#{db_name}?authSource=#{input 'mongo_auth_source'}&tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{get_users}\""

    # run the command and parse the output as json
    users_output = json({ command: run_get_users }).params

    users_output['users'].each do |user|
      # check if user is not a superuser
      next if input('mongo_superusers').include?(user['user'])

      # check each users role
      describe "User roles of #{user['_id']}" do
        # collect all roles for user
        subject { user['roles'].map { |role| role['role'] } }
        it { should_not include 'dbOwner' }
      end
    end
  end
end
