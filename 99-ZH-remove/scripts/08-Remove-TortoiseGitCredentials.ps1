#requires -version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Regular expression matched against the credential target name.
    [string] $Pattern = '(?i)^(tortoisegit|git:)',

    # Show matching credentials without deleting them.
    [switch] $ListOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('NativeCredentialManager' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class NativeCredentialManager
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL
    {
        public UInt32 Flags;
        public UInt32 Type;
        public IntPtr TargetName;
        public IntPtr Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public UInt32 CredentialBlobSize;
        public IntPtr CredentialBlob;
        public UInt32 Persist;
        public UInt32 AttributeCount;
        public IntPtr Attributes;
        public IntPtr TargetAlias;
        public IntPtr UserName;
    }

    public sealed class CredentialInfo
    {
        public string TargetName { get; set; }
        public string UserName { get; set; }
        public UInt32 Type { get; set; }
    }

    [DllImport("advapi32.dll", EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode,
        SetLastError = true)]
    private static extern bool CredEnumerate(string filter, UInt32 flags,
        out UInt32 count, out IntPtr credentials);

    [DllImport("advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode,
        SetLastError = true)]
    private static extern bool CredDelete(string target, UInt32 type, UInt32 flags);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern void CredFree(IntPtr buffer);

    public static CredentialInfo[] Enumerate()
    {
        UInt32 count;
        IntPtr credentials;
        if (!CredEnumerate(null, 0, out count, out credentials))
        {
            int error = Marshal.GetLastWin32Error();
            if (error == 1168) return new CredentialInfo[0]; // ERROR_NOT_FOUND
            throw new Win32Exception(error);
        }

        try
        {
            CredentialInfo[] result = new CredentialInfo[count];
            for (int i = 0; i < count; i++)
            {
                IntPtr credentialPtr = Marshal.ReadIntPtr(credentials, i * IntPtr.Size);
                CREDENTIAL credential = (CREDENTIAL)Marshal.PtrToStructure(
                    credentialPtr, typeof(CREDENTIAL));
                result[i] = new CredentialInfo {
                    TargetName = Marshal.PtrToStringUni(credential.TargetName),
                    UserName = credential.UserName == IntPtr.Zero
                        ? null : Marshal.PtrToStringUni(credential.UserName),
                    Type = credential.Type
                };
            }
            return result;
        }
        finally { CredFree(credentials); }
    }

    public static void Delete(string target, UInt32 type)
    {
        if (!CredDelete(target, type, 0))
            throw new Win32Exception(Marshal.GetLastWin32Error());
    }
}
'@
}

try {
    $null = [regex]::new($Pattern)
}
catch {
    throw "Некорректное регулярное выражение -Pattern: $Pattern"
}

$credentials = @(
    [NativeCredentialManager]::Enumerate() |
        Where-Object { $_.TargetName -match $Pattern } |
        Sort-Object TargetName, Type
)

if ($credentials.Count -eq 0) {
    Write-Host "Подходящие учётные данные не найдены."
    return
}

$credentials | Format-Table TargetName, UserName, Type -AutoSize

if ($ListOnly) {
    return
}

$deleted = 0
foreach ($credential in $credentials) {
    $description = "удалить учётные данные пользователя '$($credential.UserName)'"
    if ($PSCmdlet.ShouldProcess($credential.TargetName, $description)) {
        [NativeCredentialManager]::Delete($credential.TargetName, $credential.Type)
        $deleted++
    }
}

Write-Host "Удалено записей: $deleted"
Write-Host "Перезапустите TortoiseGit или повторите операцию Git для новой авторизации."
