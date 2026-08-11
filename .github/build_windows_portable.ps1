param(
    [string]$LazarusDir = 'C:\lazarus'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -Raw (Join-Path $repoDir 'VERSION.txt')).Trim()
$buildTarget = 'x86_64-win64'
$stageRoot = Join-Path $repoDir 'Release'
$bundleDir = Join-Path $stageRoot "transgui-$version-$buildTarget"
$zipPath = Join-Path $stageRoot "transgui-$version-$buildTarget.zip"

Push-Location $repoDir
try {
    $env:Path = "$LazarusDir;$LazarusDir\fpc\3.2.2\bin\x86_64-win64;$env:Path"
    $env:LAZARUS_DIR = $LazarusDir

    lazbuild -B --lazarusdir="$LazarusDir" transgui.lpi
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    make clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    make all
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    upx --best .\transgui.exe
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Remove-Item $bundleDir, $zipPath -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $bundleDir 'lang') -Force | Out-Null

    @(
        'transgui.exe',
        'README.md',
        'readme.txt',
        'history.txt',
        'LICENSE',
        'transgui.png',
        'transgui.ico'
    ) | ForEach-Object {
        Copy-Item (Join-Path $repoDir $_) $bundleDir -Force
    }

    Copy-Item (Join-Path $repoDir 'lang\transgui.*') (Join-Path $bundleDir 'lang') -Force
    Copy-Item (Join-Path $repoDir 'setup\win_amd64\openssl\libcrypto-3-x64.dll') $bundleDir -Force
    Copy-Item (Join-Path $repoDir 'setup\win_amd64\openssl\libssl-3-x64.dll') $bundleDir -Force

    Compress-Archive -Path (Join-Path $bundleDir '*') -DestinationPath $zipPath -CompressionLevel Optimal
    Get-FileHash $zipPath -Algorithm SHA256
}
finally {
    Pop-Location
}
