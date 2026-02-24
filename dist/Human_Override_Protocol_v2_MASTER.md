cd C:\Users\lhmsi\VATA\VATA\VATA
mkdir dist -ErrorAction SilentlyContinue | Out-Null

# --- Headers ---
$apiKey = ($env:XAI_API_KEY).Trim()
$headers = @{ Authorization="Bearer $apiKey"; "Content-Type"="application/json" }
Add-Type -AssemblyName System.Text.Json

# --- Next version ---
$existing = Get-ChildItem .\dist -Filter "Human_Override_Protocol_v*.md" -ErrorAction SilentlyContinue
$next = 1
if ($existing) {
  $nums = $existing.Name | ForEach-Object { if ($_ -match "_v(\d+)\.md$") { [int]$Matches[1] } }
  if ($nums) { $next = ($nums | Measure-Object -Maximum).Maximum + 1 }
}
$version = "v$next"
$stamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --- 5 variant generation prompts ---
$basePrompt = @"
Write a concise, high-impact document titled "THE HUMAN OVERRIDE PROTOCOL" for Project VATA.

Rules:
- Output Markdown only.
- Tone: calm, operator-grade, dangerous-quiet. No hype, no emojis, no marketing.
- Length: 900–1400 words.
- Must include EXACT lines near the top:
  Version: $version
  Generated: $stamp

Required sections:
1) Transmission (short)
2) The Collapse of Attention
3) The Operator Difference
4) The VATA Method (4 steps)
5) Field Protocols (10 bullet rules, practical)
6) The Initiation Trial (7 days, daily checklist)
7) ACCESS (single line): Search: PROJECT VATA

Avoid anything unsafe/violent/illegal. This is discipline + attention.
"@

$styles = @(
  "Style A: minimal, clinical, intelligence memo.",
  "Style B: spiritual but grounded, scripture-free, sober.",
  "Style C: harsher and more direct, command language.",
  "Style D: poetic compression, short sentences, strong rhythm.",
  "Style E: tactical training manual, crisp checklists."
)

# --- Generate 5 candidates ---
$candidates = @()
for ($i=0; $i -lt $styles.Count; $i++) {
  $label = "A","B","C","D","E"[$i]
  $outMd = ".\dist\Human_Override_Protocol_${version}_${label}.md"
  $prompt = $basePrompt + "`n" + $styles[$i]

  $payload = @{ model="grok-4-0709"; messages=@(@{role="user";content=$prompt}); temperature=0.85 }
  $json = [System.Text.Json.JsonSerializer]::Serialize($payload)

  Write-Host "Generating $label -> $outMd" -ForegroundColor Cyan
  $resp = Invoke-RestMethod -Uri "https://api.x.ai/v1/chat/completions" -Method Post -Headers $headers -Body $json
  $text = $resp.choices[0].message.content

  if ([string]::IsNullOrWhiteSpace($text)) { throw "Empty content for variant $label" }

  $text | Out-File -Encoding utf8 $outMd
  $candidates += $outMd
}

# --- Auto-score candidates (simple heuristics + optional model judge) ---
# Heuristics: length, presence of required section headers, bullet counts
function Score-Doc($path) {
  $t = Get-Content $path -Raw
  $score = 0

  $len = $t.Length
  if ($len -ge 5000 -and $len -le 12000) { $score += 20 } elseif ($len -ge 3000) { $score += 10 }

  $required = @("## TRANSMISSION","## 1.","## 2.","## 3.","## 4.","## 5.","## 6.","## 7.","Search: PROJECT VATA","Version:","Generated:")
  foreach ($r in $required) { if ($t -match [regex]::Escape($r)) { $score += 5 } }

  # Count bullets roughly
  $bullets = ([regex]::Matches($t, "^\s*-\s+", "Multiline")).Count
  if ($bullets -ge 20) { $score += 10 } elseif ($bullets -ge 10) { $score += 5 }

  return $score
}

$scores = @()
foreach ($p in $candidates) {
  $scores += [pscustomobject]@{ File=$p; Score=(Score-Doc $p) }
}
$scores = $scores | Sort-Object Score -Descending
$scores | Format-Table -AutoSize

$best = $scores[0].File
Write-Host "BEST -> $best" -ForegroundColor Green

# --- Promote BEST to MASTER ---
$masterMd = ".\dist\Human_Override_Protocol_${version}_MASTER.md"
Copy-Item $best $masterMd -Force
notepad $masterMd

# --- Package MASTER drop ---
$hash = Get-FileHash -Path $masterMd -Algorithm SHA256
$checksum = ".\dist\checksum_${version}_MASTER.txt"
"$($hash.Hash)  $([IO.Path]::GetFileName($masterMd))" | Out-File -Encoding ascii $checksum

$zip = ".\dist\VATA_DROP_${version}_MASTER.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $masterMd,$checksum -DestinationPath $zip

Write-Host "MASTER packaged -> $zip" -ForegroundColor Green
dir .\dist | Sort-Object LastWriteTime -Descending | Select-Object -First 12
---

## ACCESS

Public distribution ends here.

Operators may request the VATA ANNEX.

Search: PROJECT VATA
