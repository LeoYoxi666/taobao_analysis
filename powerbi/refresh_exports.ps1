param(
    [string]$DatabaseHost = "localhost",
    [int]$Port = 5432,
    [string]$Database = "taobao_analysis",
    [string]$User = "postgres"
)

$ErrorActionPreference = "Stop"

$powerBiRoot = $PSScriptRoot
$queryDirectory = Join-Path $powerBiRoot "queries"
$outputDirectory = Join-Path $powerBiRoot "data"
$errorLogPath = Join-Path $powerBiRoot "last_export_error.log"

if (Test-Path -LiteralPath $errorLogPath) {
    Remove-Item -LiteralPath $errorLogPath -Force
}

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
if ($null -ne $psqlCommand) {
    $psqlPath = $psqlCommand.Source
} elseif (Test-Path -LiteralPath "D:\PostgreSQL17\bin\psql.exe") {
    $psqlPath = "D:\PostgreSQL17\bin\psql.exe"
} else {
    throw "psql was not found. Add PostgreSQL bin to PATH or update this script."
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$exports = @(
    @{
        Query = "01_user_behaviour_overview.sql"
        Output = "user_behaviour_overview.csv"
        ExpectedRows = 4
    },
    @{
        Query = "02_hourly_activity_trend.sql"
        Output = "hourly_activity_trend.csv"
        ExpectedRows = 24
    },
    @{
        Query = "03_purchase_funnel.sql"
        Output = "purchase_funnel.csv"
        ExpectedRows = 3
    },
    @{
        Query = "04_product_category_ranking.sql"
        Output = "product_category_ranking.csv"
        ExpectedRows = 20
    },
    @{
        Query = "05_user_segmentation.sql"
        Output = "user_segmentation.csv"
        ExpectedRows = 4
    },
    @{
        Query = "06_weekday_hour_behaviour.sql"
        Output = "weekday_hour_behaviour.csv"
        ExpectedRows = 672
    },
    @{
        Query = "07_weekday_hour_purchase_rate.sql"
        Output = "weekday_hour_purchase_rate.csv"
        ExpectedRows = 168
    },
    @{
        Query = "08_daily_behaviour_trend.sql"
        Output = "daily_behaviour_trend.csv"
        ExpectedRows = 124
    },
    @{
        Query = "09_user_activity_distribution.sql"
        Output = "user_activity_distribution.csv"
        ExpectedRows = 22
    },
    @{
        Query = "10_behaviour_transition_matrix.sql"
        Output = "behaviour_transition_matrix.csv"
        ExpectedRows = 20
    },
    @{
        Query = "11_behaviour_depth_conversion.sql"
        Output = "behaviour_depth_conversion.csv"
        ExpectedRows = 24
    },
    @{
        Query = "12_activity_category_preference.sql"
        Output = "activity_category_preference.csv"
        ExpectedRows = 15
    }
)

$passwordWasSetByScript = $false
$previousPgOptions = $env:PGOPTIONS

if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    $securePassword = Read-Host "PostgreSQL password for $User" -AsSecureString
    $credential = [System.Management.Automation.PSCredential]::new(
        $User,
        $securePassword
    )
    $env:PGPASSWORD = $credential.GetNetworkCredential().Password
    $passwordWasSetByScript = $true
}

try {
    $env:PGOPTIONS = "-c default_transaction_read_only=on"

    foreach ($export in $exports) {
        $queryPath = Join-Path $queryDirectory $export.Query
        $outputPath = Join-Path $outputDirectory $export.Output
        $temporaryOutputPath = "$outputPath.tmp"

        try {
            if (Test-Path -LiteralPath $temporaryOutputPath) {
                Remove-Item -LiteralPath $temporaryOutputPath -Force
            }

            $psqlMessages = @(
                & $psqlPath `
                    -X `
                    -q `
                    --csv `
                    -h $DatabaseHost `
                    -p $Port `
                    -U $User `
                    -d $Database `
                    -v ON_ERROR_STOP=1 `
                    -f $queryPath `
                    -o $temporaryOutputPath 2>&1
            )

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Export failed: {0}`n{1}" `
                    -f $export.Query, ($psqlMessages -join "`n")
                )
            }

            $rows = @(Import-Csv -LiteralPath $temporaryOutputPath)
            if ($rows.Count -ne $export.ExpectedRows) {
                throw (
                    "Unexpected row count for {0}: expected {1}, received {2}" `
                    -f $export.Output, $export.ExpectedRows, $rows.Count
                )
            }

            Move-Item `
                -LiteralPath $temporaryOutputPath `
                -Destination $outputPath `
                -Force

            Write-Host (
                "Exported {0} rows to {1}" -f $rows.Count, $export.Output
            )
        }
        finally {
            if (Test-Path -LiteralPath $temporaryOutputPath) {
                Remove-Item -LiteralPath $temporaryOutputPath -Force
            }
        }
    }
}
catch {
    [System.IO.File]::WriteAllText(
        $errorLogPath,
        ($_ | Out-String)
    )
    throw
}
finally {
    if ($null -eq $previousPgOptions) {
        Remove-Item Env:PGOPTIONS -ErrorAction SilentlyContinue
    } else {
        $env:PGOPTIONS = $previousPgOptions
    }

    if ($passwordWasSetByScript) {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}
