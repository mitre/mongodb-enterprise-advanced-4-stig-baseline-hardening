# Use 'include_controls' to pull in dependencies defined in inspec.yml
# You can also write overrides to dependency controls in this file
# See https://docs.chef.io/inspec/profiles/#profile-dependencies

control 'foobar' do
    title 'Foobar'
    desc 'This is a test control'
    describe file('/tmp') do
        it { should be_directory }
    end
end