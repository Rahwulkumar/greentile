param(
  [string]$EntryDate
)

$timestamp = if ($EntryDate) {
  [DateTimeOffset]::Parse($EntryDate)
} else {
  [DateTimeOffset]::UtcNow
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $repoRoot "data"
$logFile = Join-Path $dataDir "green-log.jsonl"

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

$verbs = @(
  "sync",
  "refresh",
  "sprout",
  "pulse",
  "nudge",
  "bloom",
  "tint",
  "water"
)

$nouns = @(
  "leaf",
  "tile",
  "graph",
  "garden",
  "pixel",
  "branch",
  "square",
  "streak"
)

$entry = [ordered]@{
  id = [guid]::NewGuid().ToString("N").Substring(0, 12)
  committed_at = $timestamp.ToUniversalTime().ToString("o")
  note = "{0} {1}" -f ($verbs | Get-Random), ($nouns | Get-Random)
}

($entry | ConvertTo-Json -Compress) | Add-Content -Path $logFile
