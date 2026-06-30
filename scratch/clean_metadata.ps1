$permSetDir = "c:\Users\Bhanu Bobba\Documents\CGCCloud\CGCMain\CGCLOUD\force-app\main\default\permissionsets"
$profileDir = "c:\Users\Bhanu Bobba\Documents\CGCCloud\CGCMain\CGCLOUD\force-app\main\default\profiles"

# 1. PERMISSION SETS TO KEEP (Auto-generated/agent related + our custom one)
$permSetsToKeep = @(
    "Visit_Intel_Access.permissionset-meta.xml",
    "CGC_Visit_Intelligence_Agent615280472_Permissions.permissionset-meta.xml",
    "Dummy_Agent446665786_Permissions.permissionset-meta.xml",
    "NextGen_1bYBh00000004gLMAQ_Permissions.permissionset-meta.xml",
    "NextGen_1bYBh00000004tFMAQ_Permissions.permissionset-meta.xml",
    "NextGen_1bYBh00000004urMAA_Permissions.permissionset-meta.xml",
    "NextGen_1bYBh00000005m5MAA_Permissions.permissionset-meta.xml",
    "NextGen_1bYBh00000005u9MAA_Permissions.permissionset-meta.xml",
    "Test_Agent2023964738_Permissions.permissionset-meta.xml",
    "Test_Agent406342780_Permissions.permissionset-meta.xml",
    "Test_Agent446950523_Permissions.permissionset-meta.xml",
    "VI1008516113_Permissions.permissionset-meta.xml",
    "VI607987324_Permissions.permissionset-meta.xml",
    "VI697993308_Permissions.permissionset-meta.xml",
    "Visit_Intelligence1416298998_Permissions.permissionset-meta.xml",
    "Visit_Intelligence_CGC642790890_Permissions.permissionset-meta.xml"
)

# 2. PROFILES TO KEEP (System Admin + CG Cloud User + Auto-generated Agent profiles)
$profilesToKeep = @(
    "Admin.profile-meta.xml",
    "CGCloud_User_Profile.profile-meta.xml",
    "Einstein Agent User.profile-meta.xml",
    "External Einstein Agent User.profile-meta.xml"
)

Write-Host "=== Starting Local Metadata Cleanup ==="

# Clean Permission Sets
Get-ChildItem $permSetDir | ForEach-Object {
    if ($permSetsToKeep -notcontains $_.Name) {
        Write-Host "Deleting permission set: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}

# Clean Profiles
Get-ChildItem $profileDir | ForEach-Object {
    if ($profilesToKeep -notcontains $_.Name) {
        Write-Host "Deleting profile: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}

Write-Host "=== Cleanup Completed! ==="
