# @Title: Rename Ethernet Adapters
# @Description: Renames network adapters for TwinCAT fieldbus operations
# @Phase: 02-SystemConfiguration
# @Order: 02
# @Dependencies: None
# @Optional: false

# Rename Ethernet adapters
Write-Log "Renaming Ethernet adapters..." "SUCCESS"

$adapterMappings = @{
    "X001" = "Fieldbus"
}

foreach ($oldName in $adapterMappings.Keys) {
    $newName = $adapterMappings[$oldName]
    Write-Log "  Renaming '$oldName' to '$newName'"

    try {
        $adapter = Get-NetAdapter -Name $oldName -ErrorAction SilentlyContinue
        if ($adapter) {
            Rename-NetAdapter -Name $oldName -NewName $newName
            Write-Log "  ✓ Renamed $oldName to $newName" "SUCCESS"
        } else {
            Write-Warning "Adapter '$oldName' not found, skipping..."
        }
    } catch {
        Write-Warning "Failed to rename $oldName to $newName : $_"
    }
}

return $true