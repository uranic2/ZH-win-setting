Get-AppxPackage *bingweather* | Remove-AppxPackage
Get-AppxPackage *getstarted* | Remove-AppxPackage
Get-AppxPackage *windowsmaps* | Remove-AppxPackage
Get-AppxPackage *FeedbackHub* | Remove-AppxPackage
Get-AppxPackage *Clipchamp* | Remove-AppxPackage
Get-AppxPackage *ZuneVideo* | Remove-AppxPackage

Get-AppxPackage MicrosoftTeams* | Remove-AppxPackage -AllUsers
Write-Host ' Microsoft Teams removed successfully!' -ForegroundColor Green

# Автоматическое удаление Microsoft To Do, если оно снова появится в системе
Get-AppxPackage *Todos* | Remove-AppxPackage -ErrorAction SilentlyContinue
Write-Host 'Microsoft To Do removed successfully!' -ForegroundColor Green
#Get-AppxPackage *xbox* | Remove-AppxPackage
