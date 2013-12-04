function Enable-BoxstarterVM {
    [CmdletBinding()]
    param(
        [string]$VMName,
        [string]$VMCheckpoint
    )
    Invoke-Verbosely -Verbose:($PSBoundParameters['Verbose'] -eq $true) {
        $vm=Get-VM $vmName -ErrorAction SilentlyContinue
        if($vm -eq $null){
            throw New-Object -TypeName InvalidOperationException -ArgumentList "Could not find VM: $vmName"
        }
        if($vmCheckpoint -ne $null -and $vmCheckpoint.Length -gt 0){
            $point = Get-VMSnapshot -VMName $vmName -Name $vmCheckpoint -ErrorAction SilentlyContinue
            if($point -ne $null) {
                Restore-VMSnapshot $vm -Name $vmCheckpoint -Confirm:$false
                $restored=$true
            }
        }
        if($vm.State -eq "saved"){
            Remove-VMSavedState $vmName
        }
        else {
            Write-BoxstarterMessage "Stopping $VMName"
            Stop-VM $VmName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        }
        $vhd=Get-VMHardDiskDrive -VMName $vmName

        $computerName = Enable-BoxstarterVHD $vhd.Path
        Start-VM $VmName
        Write-BoxstarterMessage "Started $VMName. Waiting for Heartbeat..."
        do {Start-Sleep -milliseconds 100} 
        until ((Get-VMIntegrationService $vm | ?{$_.name -eq "Heartbeat"}).PrimaryStatusDescription -eq "OK")
        if(!$restored) {
            Write-BoxstarterMessage "Creating Checkpoint $vmCheckpoint"
            Checkpoint-VM -Name $vmName -SnapshotName $vmCheckpoint
        }
        return "$computerName"
    }
}