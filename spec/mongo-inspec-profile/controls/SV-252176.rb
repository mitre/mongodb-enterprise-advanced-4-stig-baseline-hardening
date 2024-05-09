control 'SV-252176' do
  title 'MongoDB must require users to reauthenticate when organization-defined circumstances or situations require reauthentication.'
  desc 'The DoD standard for authentication of an interactive user is the presentation of a Common Access Card (CAC) or other physical token bearing a valid, current, DoD-issued Public Key Infrastructure (PKI) certificate, coupled with a Personal Identification Number (PIN) to be entered by the user at the beginning of each session and whenever reauthentication is required.

Without reauthentication, users may access resources or perform tasks for which they do not have authorization.

When applications provide the capability to change security roles or escalate the functional capability of the application, it is critical the user reauthenticate.

In addition to the reauthentication requirements associated with session locks, organizations may require reauthentication of individuals and/or devices in other situations, including (but not limited to) the following circumstances:

(i) When authenticators change;
(ii) When roles change;
(iii) When security categories of information systems change;
(iv) When the execution of privileged functions occurs;
(v) After a fixed period of time; or
(vi) Periodically.

Within the DoD, the minimum circumstances requiring reauthentication are privilege escalation and role changes.'
  desc 'check', %q(MongoDB Enterprise supports PKI x.509 certificate bearer authentication.

The duration of a user's logical session is application-specific, but is verified on initial network session connection. Additional user authentication controls can be enabled on a client basis (including Windows OS-level CAC + PIN flow; see operating system documentation for specific configuration).

By specifying both the database and the collection in the resource document for a privilege, administrator can limit the privilege actions just to a specific collection in a specific database. Each privilege action in a role can be scoped to a different collection.

When a new privilege is applied to an object, such as a particular collection or a database, authorization to access that object is verified at run-time (i.e., in real time).

To check that authorization is being enforced, see the documentation for Collection-Level Access Control and custom user roles (https://docs.mongodb.com/v4.4/core/collection-level-access-control/) and create a new role with the following permissions, e.g.:

 use admin
 db.createRole(
   {
     role: "myTestRole",
     privileges: [
       { resource: { db: "products", collection: "inventory" }, actions: [ "find", "update", "insert" ] },
       { resource: { db: "products", collection: "orders" },  actions: [ "find" ] }
     ],
     roles: [ ]
   },
   { w: "majority" , wtimeout: 5000 }
)

Assign that privilege to one or more users.

 use products
 db.createUser({user: "myRoleTestUser", pwd: "password1", roles: ["myTestRole"]})

Log in as "myRoleTestUser" user and attempt find(), insert() and  delete() operations on a test inventory and orders collection.

The following commands will succeed:

 use products
 db.inventory.insert({a: 1})
 db.inventory.find()
 db.inventory.update({a:1}, {$set: {"updated": true}})

Example output of the above commands:

  use products
switched to db products
 db.inventory.find()
  db.inventory.insert({a: 1})
WriteResult({ "nInserted" : 1 })
 db.inventory.update({a:1}, {$set: {"updated": true}})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 0 })

Of the following ONLY the find() will succeed:

 use products
switched to db products
 use products
 db.orders.find()
 db.orders.insert({a: 1})
 db.orders.update({a:1}, {$set: {"updated": true}})

Example output:

 db.orders.find()
 db.orders.insert({a: 1})
WriteCommandError({
        "ok" : 0,
        "errmsg" : "not authorized on products to execute command { insert: \"###\", ordered: \"###\", lsid: { id: \"###\" }, $db: \"###\" }",
        "code" : 13,
        "codeName" : "Unauthorized"
})
 db.orders.update({a:1}, {$set: {"updated": true}})
WriteCommandError({
        "ok" : 0,
        "errmsg" : "not authorized on products to execute command { update: \"###\", ordered: \"###\", lsid: { id: \"###\" }, $db: \"###\" }",
        "code" : 13,
        "codeName" : "Unauthorized"
})

In the last example above, if either or both insert() or  update() succeed, this is a finding.

Note that this check is by necessity application-specific.)
  desc 'fix', 'Determine the organization-defined circumstances or situations that require reauthentication and ensure that the mongod and mongos processes are stopped/started (restart), and ensure that the mongod configuration file has security.authentication: true set.

In the case of database- and collection-level scoped user privileges, see MongoDB documentation for guidance on application specific configuration for user privileges in order to restrict access as required:

https://docs.mongodb.com/v4.4/tutorial/manage-users-and-roles/#create-a-role-to-manage-current-operations

https://docs.mongodb.com/v4.4/core/collection-level-access-control/#privileges-and-scope'
  impact 0.5
  ref 'DPMS Target MongoDB Enterprise Advanced 4.x'
  tag check_id: 'C-55632r855516_chk'
  tag severity: 'medium'
  tag gid: 'V-252176'
  tag rid: 'SV-252176r855517_rule'
  tag stig_id: 'MD4X-00-005600'
  tag gtitle: 'SRG-APP-000389-DB-000372'
  tag fix_id: 'F-55582r813909_fix'
  tag 'documentable'
  tag cci: ['CCI-002038']
  tag nist: ['IA-11']

  create_user_command = "EJSON.stringify(db.getSiblingDB('products').createUser({user: 'myRoleTestUser', pwd: 'password1', roles: ['myTestRole']}))"

  inventory_write_command = 'EJSON.stringify(db.inventory.insert({a: 1}))'
  inventory_find_command = 'db.inventory.find()'
  inventory_update_command = "EJSON.stringify(db.inventory.update({a:1}, {\\$set: {'updated': true}}))"

  order_write_command = 'EJSON.stringify(db.orders.insert({a: 1}))'
  order_find_command = 'db.orders.find()'
  order_update_command = "db.orders.update({a:1}, {\\$set: {'updated': true}})"

  run_create_user = "mongosh \"mongodb://#{input('mongo_dba')}:#{input('mongo_dba_password')}@#{input('mongo_host')}:#{input('mongo_port')}/?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{create_user_command}\""

  run_inventory_write = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{inventory_write_command}\""
  run_inventory_find = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{inventory_find_command}\""
  run_inventory_update = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{inventory_update_command}\""

  run_order_write = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{order_write_command}\""
  run_order_find = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{order_find_command}\""
  run_order_update = "mongosh \"mongodb://myRoleTestUser:password1@#{input('mongo_host')}:#{input('mongo_port')}/products?tls=true&tlsCAFile=#{input('ca_file')}&tlsCertificateKeyFile=#{input('certificate_key_file')}\" --quiet --eval \"#{order_update_command}\""

  create_user_output = json({ command: run_create_user })
  create_user_again = command(run_create_user)

  inventory_write_output = command(run_inventory_write)
  inventory_find_output = command(run_inventory_find)
  inventory_update_output = command(run_inventory_update)

  order_write_output = command(run_order_write)
  order_find_output = command(run_order_find)
  order_update_output = command(run_order_update)

  describe.one do
    describe 'Test user' do
      it 'should be created' do
        expect(create_user_output.params['ok']).to eq(1)
      end
    end

    describe 'Test user' do
      it 'should be created' do
        expect(create_user_again.stderr).to match(/MongoServerError: User "myRoleTestUser@products" already exists/)
      end
    end
  end

  # Inventory commands
  describe 'Test user' do
    it 'should be able to write to the database' do
      expect(inventory_write_output.stdout).to match(/"acknowledged":true/)
    end
  end

  describe 'Test user' do
    it 'should be able to find documents in the database' do
      expect(inventory_find_output.stdout).to match(/_id: ObjectId/)
    end
  end

  describe 'Test user' do
    it 'should be able to update a document in the database' do
      expect(inventory_update_output.stdout).to match(/"acknowledged":true/)
    end
  end

  # Order commands
  describe 'Test user' do
    it 'should not be able to write to the database' do
      expect(order_write_output.stderr).to match(/MongoBulkWriteError: not authorized on products to execute command/)
    end
  end

  describe 'Test user' do
    it 'should not be able to find documents in the database' do
      expect(order_find_output.stdout).to match(/_id: ObjectId/)
    end
  end

  describe 'Test user' do
    it 'should not be able to update a document in the database' do
      expect(order_update_output.stderr).to match(/MongoServerError: not authorized on products to execute command/)
    end
  end
end
