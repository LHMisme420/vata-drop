# ============================
# VATA FORGE v2 (Grok-powered)
# Outputs: MD + checksum + ZIP drop
# ============================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Config ---
$Model     = "grok-4-0709"
$BaseUrl   = "https://api.x.ai/v1/chat/completions"
$ApiKey    = ($env:XAI_API_KEY).Trim()

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw "XAI_API_KEY is empty. Set it first: `$env:XAI_API_KEY = '...'"
}

# Versioning: v1, v2, v3... based on existing files
if (!(Test-Path "dist")) { New-Item -ItemType Directory -Path "dist" | Out-Null }

$existing = Get-ChildItem -Path "dist" -Filter "Human_Override_Protocol_v*.md" -ErrorAction SilentlyContinue
$nextNum = 1
if ($existing) {
  $nums = $existing.Name |
    ForEach-Object { if ($_ -match "_v(\d+)\.md$") { [int]$Matches[1] } } |
    Where-Object { $_ -is [int] }
  if ($nums) { $nextNum = ($nums | Measure-Object -Maximum).Maximum + 1 }
}
$Version   = "v$nextNum"
$Stamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$OutMd     = "dist\Human_Override_Protocol_$Version.md"

# --- Prompt (high-signal, mythic, useful, not cringe) ---
$Prompt = @"
Write a concise, high-impact document titled "THE HUMAN OVERRIDE PROTOCOL" for Project VATA.

Constraints:
- Output MUST be valid Markdown only.
- Tone: calm, dangerous-quiet, operator-grade. No hype, no emojis, no marketing voice.
- Length: ~900–1400 words.
- Include: Version line and Generated timestamp placeholders exactly as shown:
  Version: $Version
  Generated: $Stamp
- Structure:
  1) Transmission (short)
  2) The Collapse of Attention (clear)
  3) The Operator Difference (clear)
  4) The VATA Method (4-step method)
  5) Field Protocols (10 bullet rules, practical)
  6) The Initiation Trial (7-day challenge with a daily checklist)
  7) Closing: "ACCESS" section with a single line: "Search: PROJECT VATA"
- Avoid: references to illegal activity, violence, weapons, hate, or anything unsafe. This is about discipline and attention.
- Make it feel like an internal memo that leaked—without claiming it actually leaked.

Now write the document.
"@

# --- Call Grok ---
$headers = @{
  Authorization = "Bearer $ApiKey"
  "Content-Type" = "application/json"
}

$bodyObj = @{
  model = $Model
  messages = @(
    @{ role = "user"; content = $Prompt }
  )
  temperature = 0.7
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 6 -Compress

Write-Host "Generating $OutMd using $Model ..." -ForegroundColor Cyan

$response = Invoke-RestMethod -Uri $BaseUrl -Method Post -Headers $headers -Body $bodyJson
$content = $response.choices[0].message.content

if ([string]::IsNullOrWhiteSpace($content)) {
  throw "Model returned empty content."
}

# --- Write MD ---
$content | Out-File -Encoding utf8 $OutMd
Write-Host "MD generated -> $OutMd" -ForegroundColor Green

# --- Checksum ---
$hash = Get-FileHash -Path $OutMd -Algorithm SHA256
$checksumFile = "dist\checksum_$Version.txt"
"$($hash.Hash)  $([IO.Path]::GetFileName($OutMd))" | Out-File -Encoding ascii $checksumFile
Write-Host "Checksum -> $checksumFile" -ForegroundColor Green

# --- Zip drop ---
$zipPath = "dist\VATA_DROP_$Version.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path $OutMd, $checksumFile -DestinationPath $zipPath
Write-Host "Drop packaged -> $zipPath" -ForegroundColor Green

# --- Quick preview (first 25 lines) ---
Write-Host "`n--- Preview (top) ---" -ForegroundColor DarkGray
Get-Content $OutMd -TotalCount 25