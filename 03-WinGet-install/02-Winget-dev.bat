winget upgrade --all
winget install -e --id DBeaver.DBeaver.Community --accept-source-agreements
rem winget install -e --id TortoiseSVN.TortoiseSVN --accept-source-agreements
winget install -e --id TortoiseGit.TortoiseGit --accept-source-agreements
winget install --id TortoiseSVN.TortoiseSVN -e --force --custom "ADDLOCAL=DefaultFeature,CLI"
winget install -e --id MarkText.MarkText
