param(
  [int]$Days = 365,
  [int]$MinCommitsPerDay = 1,
  [int]$MaxCommitsPerDay = 3
)

if ($Days -lt 1) {
  throw "Days must be at least 1."
}

if ($MinCommitsPerDay -lt 1) {
  throw "MinCommitsPerDay must be at least 1."
}

if ($MaxCommitsPerDay -lt $MinCommitsPerDay) {
  throw "MaxCommitsPerDay must be greater than or equal to MinCommitsPerDay."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
  if (-not (Test-Path ".git")) {
    throw "Run this script from a git repository after git init and the first commit."
  }

  for ($offset = $Days - 1; $offset -ge 0; $offset--) {
    $dayStart = [DateTimeOffset]::UtcNow.Date.AddDays(-$offset)
    $count = Get-Random -Minimum $MinCommitsPerDay -Maximum ($MaxCommitsPerDay + 1)
    $currentDay = [DateTimeOffset]::UtcNow.Date
    $maxMinute = if ($dayStart -eq $currentDay) {
      [Math]::Max(1, [int][Math]::Floor(([DateTimeOffset]::UtcNow - $dayStart).TotalMinutes) + 1)
    } else {
      1440
    }
    $stamps = @()

    for ($i = 0; $i -lt $count; $i++) {
      $minuteOfDay = Get-Random -Minimum 0 -Maximum $maxMinute
      $stamps += $dayStart.AddMinutes($minuteOfDay)
    }

    $stamps = $stamps | Sort-Object

    foreach ($stamp in $stamps) {
      & "$PSScriptRoot/write-green-entry.ps1" -EntryDate $stamp.ToString("o")
      git add data/green-log.jsonl
      git diff --cached --quiet

      if ($LASTEXITCODE -eq 0) {
        continue
      }

      $iso = $stamp.ToString("o")
      $env:GIT_AUTHOR_DATE = $iso
      $env:GIT_COMMITTER_DATE = $iso

      git commit -m "chore: backfill graph green $($stamp.ToString('yyyy-MM-dd'))"
    }
  }
}
finally {
  Pop-Location
}
