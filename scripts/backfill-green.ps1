param(
  [datetime]$StartDate,
  [datetime]$EndDate = [DateTime]::UtcNow.Date,
  [int]$MinCommitsPerDay = 1,
  [int]$MaxCommitsPerDay = 3,
  [double]$WeekdayCommitChance = 0.72,
  [double]$WeekendCommitChance = 0.38
)

if (-not $StartDate) {
  $StartDate = [DateTime]::UtcNow.Date.AddDays(-364)
}

if ($MinCommitsPerDay -lt 1) {
  throw "MinCommitsPerDay must be at least 1."
}

if ($MaxCommitsPerDay -lt $MinCommitsPerDay) {
  throw "MaxCommitsPerDay must be greater than or equal to MinCommitsPerDay."
}

$startDay = [DateTimeOffset]::new($StartDate.Date, [TimeSpan]::Zero)
$endDay = [DateTimeOffset]::new($EndDate.Date, [TimeSpan]::Zero)

if ($endDay -lt $startDay) {
  throw "EndDate must be greater than or equal to StartDate."
}

if ($WeekdayCommitChance -lt 0 -or $WeekdayCommitChance -gt 1) {
  throw "WeekdayCommitChance must be between 0 and 1."
}

if ($WeekendCommitChance -lt 0 -or $WeekendCommitChance -gt 1) {
  throw "WeekendCommitChance must be between 0 and 1."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
  if (-not (Test-Path ".git")) {
    throw "Run this script from a git repository after git init and the first commit."
  }

  for ($dayStart = $startDay; $dayStart -le $endDay; $dayStart = $dayStart.AddDays(1)) {
    $isWeekend = $dayStart.DayOfWeek -in @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)
    $commitChance = if ($isWeekend) { $WeekendCommitChance } else { $WeekdayCommitChance }

    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -gt $commitChance) {
      continue
    }

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
