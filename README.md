# Kitchen::VMM

|Travis CI|Gem|
|-----|-----|
| [![Build Status](https://travis-ci.org/jarig/kitchen-vmm.svg?branch=master)](https://travis-ci.org/jarig/kitchen-vmm)|[![Gem Version](https://badge.fury.io/rb/kitchen-vmm.svg)](http://badge.fury.io/rb/kitchen-vmm)|

Supports: Windows, Linux

Virtual Machine Management plugin for Kitchen.

This provider will allow you to create VMs in the remote Virtual Machine Manager via Test Kitchen.

## Installation

Install kitchen-vmm gem

```ruby
chef gem 'kitchen-vmm'
```

## Prerequisites

1. You should have template in your VMM which has following things setup:
   - WinRM and firewall configured, using:
   ```
   winrm quickconfig
   ```
   - Either domain or local user with admin rights.
   You can specify its creds using
   (either in cookbook .kitchen.yml or in $HOME/.kitchen/config.yml):
   ```yaml
   transport:
       name: winrm
       username: <username>
       password: <password>
   ```
   - Once VM created in VMM it should automatically get IP assigned, as well as it should be directly accessible from your machine.
2. Run kitchen commands under **Administrator** (in admin shell).

## Usage

In the .kitchen.yml

### Configure Driver

Globally
```yaml
driver:
  name: vmm
  vm_template_name: default-template
  vm_host_group_name: default-group
```

Or per platform
```yaml
platforms:
- name: platform1
  driver:
    name: vmm
    vm_template_name: 'overidden-template'
    vm_host_group_name: overidden-group
```

### Configure Transport

In case you need to create both Linux and Windows machines, then different transport types have to be used(ssh for linux and winrm for windows).
For easier maintenance and cleaner configuration you can create global kitchen configuration under $HOME/[username]/.kitchen/config.yml with following contents:

```yaml
<% WINRM_USERNAME = 'winrm_user' %>
<% WINRM_PASSWORD = 'winrm_dassword' %>

# default transport settings
transport:
  name: ssh
  username: ssh_user
  ssh_key: <path_to_key>
  # winrm related settings that do not clash with ssh ones can also go here
  # example: winrm_transport
```

Then in your cookbook specific kitchen.yml configure transport either for platform or suite
```yaml
suites:
- name: windows-basic
  run_list:
  - recipe[windows-basic::default]
  transport:
    name: winrm
    username: <%= WINRM_USERNAME %>
    password: <%= WINRM_PASSWORD %>
```

### Required parameters:

* #### vm_template_name

  VMM template name that will be used for VM creation.

  ```yaml
  driver_config:
    ...
    vm_template_name: vagrant-template-w8.1-64
  ```

* #### vm_host_group_name

  VMM host group where VM will be placed.
  NOTE: Your template or *vm_hardware_profile* should match it as well.

  ```yaml
  driver_config:
    ...
    vm_host_group_name: 'Host-Group-Name'
  ```

* #### vmm_server_address

  IP/Hostname of the VMM server where VMs are going to be created.
  ```yaml
  driver_config:
    ...
    vmm_server_address: '192.124.125.10'
  ```

### Optional parameters:

* #### vm_name

  Specify name of a VM that is going to be created. Default is Kitchen instance name.
  If VM with such name already exists driver might get random number appended to it.

  ```yaml
  driver_config:
    ...
    vm_name: 'my-vm-in-vmm'
  ```

* #### vm_name_prefix

  Prefix for VM name, all created VMs are going to have name prepended with the specified prefix.

  ```yaml
  driver_config:
    ...
    vm_name_prefix: tst-
  ```


* #### vm_hardware_profile

  Specify alternate HW profile that should be used instead of the one provided in your original template.

  ```yaml
  driver_config:
    ...
    vm_hardware_profile: 'TestHW-8core-8gb'
  ```

* #### proxy_server_address

  If your local machine do not have direct access to the machine that hosts VMM, but you have proxy server(jump box) you can specify its IP in *proxy_server_address* property.

  ```yaml
  driver_config:
    ...
    proxy_server_address: 'my-proxy-to-vmm'
  ```

* #### ad_server

  You can tell the provider to move your VM under some particular OU once it's created.

  URL of AD server. Can be derived by running ```echo %LOGONSERVER%``` command in CMD of the VM environment.

  Example:
  ```yaml
  driver_config:
    ...
    ad_server: 'my-ad-server.some.domain.local'
  ```

* #### ad_source_path

  Base DN container where VM appears(and it will be moved from) once it's created.
  Example:
  ```yaml
  driver_config:
    ...
    ad_source_path: 'CN=Computers,DC=some,DC=domain,DC=local'
  ```

* #### ad_target_path

  New AD path where VM should be moved to.
  Example:
  ```yaml
  driver_config:
    ...
    ad_target_path: 'OU=Vagrant,OU=Chef-Nodes,DC=some,DC=domain,DC=local'
  ```


## Troubleshooting

### Authorization failure

Check that winrm is configured properly in the VM, if username/password is  local then ensure you've set winrm transport to plaintext for kitchen.
```yaml
transport:
  name: winrm
  ...
  winrm_transport: plaintext
```
and enable basic auth and unencrypted connection in a VM.
```
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
```
and on your local machine
```
winrm set winrm/config/client/auth @{Basic="true"}
```

### Unencrypted traffic is currently disabled in the client configuration

Run following command on your machine as well:
```
winrm set winrm/config/service @{AllowUnencrypted="true"}
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/kitchen-vmm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
