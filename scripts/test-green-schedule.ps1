$ErrorActionPreference = "Stop"
$scheduleScript = Join-Path $PSScriptRoot "test-green-day.ps1"
$firstMonday = [DateTimeOffset]::Parse("2023-12-25T00:00:00+05:30")
$patterns = @()

for ($week = 0; $week -lt 160; $week++) {
  $monday = $firstMonday.AddDays(7 * $week)
  $activeDays = @()

  for ($day = 0; $day -lt 7; $day++) {
    $midnight = $monday.AddDays($day)
    $selected = & $scheduleScript -Now $midnight

    if ($selected -isnot [bool]) {
      throw "Expected a Boolean schedule decision."
    }

    foreach ($instant in @($midnight, $midnight.ToUniversalTime(), $midnight.AddDays(1).AddTicks(-1))) {
      if ((& $scheduleScript -Now $instant) -ne $selected) {
        throw "Schedule changed within the India calendar day $midnight."
      }
    }

    if ($selected) {
      $activeDays += $day
    }
  }

  if ($activeDays.Count -ne 5) {
    throw "Expected five commit days for the week starting $monday; got $($activeDays.Count)."
  }

  $patterns += $activeDays -join ","
}

if (($patterns | Sort-Object -Unique).Count -lt 2) {
  throw "The selected days never change between weeks."
}

if (-not ($patterns | Where-Object { $_ -match '[56]' })) {
  throw "The schedule never selects a weekend day."
}

Write-Host "PASS: 160 weeks have five commit days, stable retries, varying selections, and correct India day boundaries."
