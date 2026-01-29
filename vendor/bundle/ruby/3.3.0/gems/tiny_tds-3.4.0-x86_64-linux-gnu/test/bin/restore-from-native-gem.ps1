$gemVersion = (Get-Content VERSION).Trim()
$gemToUnpack = "./tiny_tds-$gemVersion-$env:RUBY_ARCHITECTURE.gem"

Write-Host "Looking to unpack $gemToUnpack"
gem unpack --target ./tmp "$gemToUnpack"

# Restore precompiled code (Gem code)
$source = (Resolve-Path ".\tmp\tiny_tds-$gemVersion-$env:RUBY_ARCHITECTURE\lib\tiny_tds").Path
$destination = (Resolve-Path ".\lib\tiny_tds").Path
Get-ChildItem $source -Recurse -Exclude "*.rb" | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}

# Restore precompiled code (ports)
$source = (Resolve-Path ".\tmp\tiny_tds-$gemVersion-$env:RUBY_ARCHITECTURE\ports").Path
New-Item -ItemType Directory -Path ".\ports" -Force
$destination = (Resolve-Path ".\ports").Path
Get-ChildItem $source -Recurse -Exclude "*.rb" | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}
