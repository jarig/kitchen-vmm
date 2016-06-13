Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_name,
  [Parameter(Mandatory=$true)]
  [string]$vmm_server_address,
  [Parameter(Mandatory=$true)]
  [string]$vm_template_name,
  [Parameter(Mandatory=$true)]
  [string]$vm_host_group_name,
  [string]$vm_hardware_profile=$null,
  [string]$proxy_server_address=$null,
  [string]$ad_server=$null,
  [string]$ad_source_path=$null,
  [string]$ad_target_path=$null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\vmm_executor.ps1"))


$script_block = {
  # external vars
  $vm_name                  = $using:vm_name
  $vm_host_group_name       = $using:vm_host_group_name
  $server_address           = $using:vmm_server_address
  $vm_template_name         = $using:vm_template_name
  $vm_hardware_profile_name = $using:vm_hardware_profile
  $ad_server                = $using:ad_server
  $ad_source_path           = $using:ad_source_path
  $ad_target_path           = $using:ad_target_path

  $description = "VM created by chef test-kitchen for testing purposes"
  $MinFreeSpaceGB = 300 #

  $domain_name = $null
  if ( $ad_source_path )
  {
    $domain_name = $($ad_source_path.split(",")|Where {$_.Contains("DC")}| ForEach-Object { $_.replace("DC=", "") }) -join "."
  }
  # Truncate vm name to 15 chars due to windows limitation
  $vm_name = $vm_name.substring(0, [math]::Min(15, $vm_name.length))

  # get VM Template object
  $VMTemplate = Get-SCVMTemplate -Name $vm_template_name
  # get host group
  $VMHostGroup = Get-VMHostGroup -Name $vm_host_group_name
  #
  Write-Host "Creating VM from template $vm_template_name"

  $tries = 10
  while ( $tries -gt 0 ) {
    $vm = Get-SCVirtualMachine -Name $vm_name
    if ( $vm -eq $null ) {
      break
    } else {
      $vm_name = $vm_name.substring(0, [math]::Min(14, $vm_name.length)) + $(Get-Random -Minimum 0 -Maximum 10)
    }
    $tries -= 1
  }
  if ( $vm -eq $null )
  {
      # Get and sort the host ratings for all the hosts in the host group.
      # select host which has rating > 0
      $hRatingHashParams = @{VMTemplate=$VMTemplate;
                             DiskSpaceGB=$MinFreeSpaceGB;
                             VMName=$vm_name;
                             VMHostGroup=$VMHostGroup;
                            }

      if ( $vm_hardware_profile_name )
      {
        $vm_hardware_profile = Get-SCHardwareProfile | where {$_.Name -eq $vm_hardware_profile_name}
        Write-host "Applying hardware profile: $vm_hardware_profile_name"
        $VMTemplate = New-SCVMTemplate -Name "Temporary Template$([guid]::NewGuid())" -VMTemplate $VMTemplate -HardwareProfile $vm_hardware_profile
      }

      $VMHost = $null
      $HostRatings = @(Get-SCVMHostRating @hRatingHashParams | Sort-Object -property Rating -descending)
      If($HostRatings.Count -eq 0) { throw "No hosts meet the requirements." }
      $VMHost = $HostRatings[0].VMHost

      # If there is at least one host that will support the virtual machine, create the virtual machine on the highest-rated host.
      If ($VMHost -ne $null )
      {
        # get placement path
        $path = $($VMHost.DiskVolumes | where { $_.IsAvailableForPlacement -eq $True } | Sort-Object -Property FreeSpace -Descending)[0]
        Write-Host "----- Creating VM ----"
        Write-Host "Host: $VMHost, $($VMHost.CPUManufacturer) $($VMHost.Rank)"
        Write-host "Placement path: $($path.Name), Free space - $($path.FreeSpace/1024/1024/1024) GB"
        Write-Host "Name: $vm_name"
        Write-Host "----- ----------- ----"
        # Create the virtual machine.
        $vmCreateParams = @{Name=$vm_name;
                            Path=$path.Name;
                            VMHost = $VMHost;
                            VMTemplate=$VMTemplate;
                            Description=$description;
                            ComputerName=$vm_name;
                            BlockDynamicOptimization=$false;
                            ReturnImmediately = $false; AnswerFile = $null;
                            StartAction = "NeverAutoTurnOnVM";
                            StopAction = "TurnOffVM";
                            StartVM=$true;
                            ErrorAction="stop";
                          }

      $vm = New-SCVirtualMachine @vmCreateParams
    } else {
      Write-Error "Cannot find suitable host for the VM."
    }
  } else {
    Write-Warning "Machine $vm_name already exists on host $($vm.VMHost.Name)"
  }
  Write-Host "Machine created."
  # try to move it in AD
  try
  {
    # move it to under AD path if required
    if ($ad_target_path -ne $null -and $ad_source_path -ne $null -and $ad_server -ne $null)
    {
      Write-host "Moving it AD under $ad_target_path"
      $cred_param = @{}
      if ($proxy_credential)
      {
        # if proxy used to overcome credssp auth
        $cred_param["Credential"] = $proxy_credential
      }
      $ad_res = Get-ADComputer -Identity:"CN=$vm_name,$ad_source_path" -Server:$ad_server -ErrorAction Ignore @cred_param
      if ( $ad_res -ne $null )
      {
        Move-ADObject -Identity:"CN=$vm_name,$ad_source_path" -TargetPath:$ad_target_path -Server:$ad_server @cred_param
      }
    }
  } catch
  {
    Write-Warning "Couldn't move under specified OU: $_"
  }

  $fqdn = $vm.ComputerNameString
  if ( ! $fqdn.contains($domain_name) )
  {
    # Linux machines do not always set domain name propery for example
    $fqdn = "$fqdn.$domain_name"
  }

  # return vm object
  @{
    vm = $vm
    fqdn = $fqdn
    ip = $ip
  }
}

$result = execute $script_block $vmm_server_address $proxy_server_address

$resultHash = @{
  hostname = $result.fqdn
  name = $result.vm.Name
  id = $result.vm.id.guid
}

$result = ConvertTo-Json $resultHash
Write-Output-Message $result
