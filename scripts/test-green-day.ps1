param(
  [DateTimeOffset]$Now = [DateTimeOffset]::UtcNow
)

$localDay = $Now.ToOffset([TimeSpan]::FromMinutes(330)).Date
$dayOfWeek = ([int]$localDay.DayOfWeek + 6) % 7
$weekStart = $localDay.AddDays(-$dayOfWeek)

# Seed from Monday so every run in the week selects the same five days.
$random = [Random]::new([int]$weekStart.ToString("yyyyMMdd"))
$commitDays = 0..6 | Sort-Object { $random.Next() } | Select-Object -First 5

$commitDays -contains $dayOfWeek
