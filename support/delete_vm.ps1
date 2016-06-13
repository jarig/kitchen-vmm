Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_id,
  [Parameter(Mandatory=$true)]
  [string]$vmm_server_address,
  [string]$proxy_server_address=$null
)


# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\vmm_executor.ps1"))


$script_block = {
  # external vars
  $vm_id  = $using:vm_id

  # Get VM
  $vm = Get-SCVirtualMachine -ID $vm_id -ErrorAction Ignore
  if ( $vm )
  {
    if ( $vm.status -eq 'Running' )
    {
      $res = Stop-VM $vm
    }
    $res = Remove-VM $vm
  } else
  {
    Write-Host "VM do not exists or not found: $vm_id"
  }
}

execute $script_block $vmm_server_address $proxy_server_address
