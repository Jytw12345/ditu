# bootstrap_python.ps1
# 当本文件夹没有 python_runtime 且系统也未安装 Python 时，
# 自动下载「便携 Python + Pillow」到 python_runtime 子目录，使 .bat 双击即用。
$ErrorActionPreference = 'Continue'
$SELF  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DEST  = Join-Path $SELF 'python_runtime'
$PYVER = '3.13.12'
$EMBED = "https://www.python.org/ftp/python/$PYVER/python-$PYVER-embed-amd64.zip"
$GETPIP= 'https://bootstrap.pypa.io/get-pip.py'

if (Test-Path (Join-Path $DEST 'python.exe')) {
    Write-Host '[bootstrap] python_runtime 已存在，跳过自动下载。'
    exit 0
}

Write-Host '[bootstrap] 开始下载便携 Python（约 15MB）…'
New-Item -ItemType Directory -Force -Path $DEST | Out-Null
$zip = Join-Path $env:TEMP 'py_embed.zip'
try {
    Invoke-WebRequest -Uri $EMBED -OutFile $zip -UseBasicParsing -TimeoutSec 180
} catch {
    Write-Host "[bootstrap] 下载失败：$_"
    Write-Host '[bootstrap] 请检查网络，或直接把含 python_runtime 的整个文件夹复制到本机。'
    exit 1
}

Write-Host '[bootstrap] 解压…'
Expand-Archive -Path $zip -DestinationPath $DEST -Force

# 启用 import site，否则 pip 安装的包不会被找到
$pth = Get-ChildItem $DEST -Filter '*.pth' | Select-Object -First 1
if ($pth) {
    $txt = (Get-Content $pth.FullName) -replace '# import site', 'import site'
    Set-Content $pth.FullName $txt
}

Write-Host '[bootstrap] 下载 get-pip.py…'
$getpip = Join-Path $DEST 'get-pip.py'
Invoke-WebRequest -Uri $GETPIP -OutFile $getpip -UseBasicParsing -TimeoutSec 120

$py = Join-Path $DEST 'python.exe'
Write-Host '[bootstrap] 安装 pip…'
& $py $getpip '--no-warn-script-location'
Write-Host '[bootstrap] 安装 Pillow…'
& $py -m pip install --no-warn-script-location Pillow

Remove-Item $zip -ErrorAction SilentlyContinue
Remove-Item $getpip -ErrorAction SilentlyContinue

if (Test-Path $py) {
    Write-Host '[bootstrap] 完成。已就绪。'
    exit 0
} else {
    Write-Host '[bootstrap] 安装未成功，请手动安装 Python 或复制带 python_runtime 的文件夹。'
    exit 1
}