require 'kitchen'
require 'kitchen/driver'
require 'kitchen/driver/vmm_version'
require 'kitchen/driver/vmm_utils'
require 'mixlib/shellout'
require 'fileutils'
require 'JSON'

module Kitchen

  module Driver

    # Driver for VMM
    class Vmm < Kitchen::Driver::Base

      kitchen_driver_api_version 2
      plugin_version Kitchen::Driver::VMM_VERSION

      default_config :vm_template_name
      default_config :vm_host_group_name
      default_config :vmm_server_address
      default_config :vm_name, nil
      default_config :vm_hardware_profile, ''
      default_config :proxy_server_address, ''
      default_config :ad_server, ''
      default_config :ad_source_path, ''
      default_config :ad_target_path, ''

      def create(state)
        @state = state
        validate_vm_settings
        create_virtual_machine
        info("VM instance #{instance.to_str} created.")
      end

      def destroy(state)
        @state = state
        instance.transport.connection(state).close
        remove_virtual_machine
        info("The VM instance #{instance.to_str} has been removed.")
        state.delete(:id)
      end

      private

      include Kitchen::Driver::VMMUtils

      def validate_vm_settings
        raise "Missing vmm_server_address" unless config[:vmm_server_address]
      end

      def kitchen_vm_path
        @kitchen_vm_path ||= File.join(config[:kitchen_root], ".kitchen/#{instance.name}")
      end

      def remove_virtual_machine
        info("Deleting virtual machine for #{instance.name}")
        options = {
            vmm_server_address: config[:vmm_server_address],
            proxy_server_address: config[:proxy_server_address],
            vm_id: @state[:id]
        }
        execute('delete_vm.ps1', options)
        info("Deleted virtual machine for #{instance.name}")
      end

      def vm_exists
        false
      end

      def create_virtual_machine
        return if vm_exists
        info("Creating virtual machine for #{instance.name}.")
        options = {
            vmm_server_address: config[:vmm_server_address],
            proxy_server_address: config[:proxy_server_address],
            vm_hardware_profile: config[:vm_hardware_profile],
            vm_name: config[:vm_name] || instance.name,
            vm_template_name: config[:vm_template_name],
            vm_host_group_name: config[:vm_host_group_name],
            ad_server: config[:ad_server],
            ad_source_path: config[:ad_source_path],
            ad_target_path: config[:ad_target_path]
        }

        #
        info("Creating and registering VM in the VMM (#{options[:vmm_server_address]})...")
        if options[:ad_server] && options[:ad_source_path] && options[:ad_target_path]
          info("  ..and moving it under #{options[:ad_target_path]} after it's created.")
        end
        vm = execute('import_vm.ps1', options)
        info("Successfully created the VM with name: #{vm['name']}")
        @state[:id] = vm['id']
        @state[:hostname] = vm['hostname']
        @state[:vm_name] = vm['name']

        info("Created virtual machine for #{instance.name}.")
      end

    end # class VMM
  end # module Driver
end # module Kitchen
