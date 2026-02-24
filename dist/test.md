$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$version = "v1"
$outMd = ".\dist\Human_Override_Protocol_$version.md"

$prompt = @"
Write Markdown titled "THE HUMAN OVERRIDE PROTOCOL" for Project VATA.
Include:
Version: $version
Generated: $stamp

Sections:
Transmission
The Collapse of Attention
The Operator Difference
The VATA Method
Field Protocols (10 bullets)
The Initiation Trial (7 days checklist)
ACCESS: Search: PROJECT VATA
"@

$payload = @{
  model = "grok-4-0709"
  messages = @(
    @{ role = "user"; content = $prompt }
  )
  temperature = 0.7
}

$bodyJson = [System.Text.Json.JsonSerializer]::Serialize($payload)

$response = Invoke-RestMethod -Uri "https://api.x.ai/v1/chat/completions" -Method Post -Headers $headers -Body $bodyJson
$content = $response.choices[0].message.content

$content | Out-File -Encoding utf8 $outMd
notepad $outMd