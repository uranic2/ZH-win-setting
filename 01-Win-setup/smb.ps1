Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force
Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
