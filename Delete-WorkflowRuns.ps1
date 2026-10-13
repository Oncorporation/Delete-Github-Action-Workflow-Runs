# ============================================
# Delete GitHub Actions Workflow Runs
# ============================================

# Check if gh is authenticated
Write-Host "Checking GitHub CLI authentication..." -ForegroundColor Cyan

$authStatus = gh auth status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to GitHub CLI." -ForegroundColor Yellow
    Write-Host "Starting authentication..." -ForegroundColor Yellow
    gh auth login

    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Authentication failed or was cancelled. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Authenticated successfully.`n" -ForegroundColor Green

# === Detect Repository (safe) ===
$DetectedRepo = $null
try {
    $repoJson = gh repo view --json nameWithOwner 2>$null
    if ($LASTEXITCODE -eq 0 -and $repoJson) {
        $DetectedRepo = ($repoJson | ConvertFrom-Json).nameWithOwner
    }
} catch {
    $DetectedRepo = $null
}

if ($DetectedRepo) {
    Write-Host "Detected repository: $DetectedRepo" -ForegroundColor Cyan
    $Repo = Read-Host "Enter repository (press Enter to use '$DetectedRepo')"
    if ([string]::IsNullOrWhiteSpace($Repo)) {
        $Repo = $DetectedRepo
    }
} else {
    Write-Host "Not inside a GitHub repository folder." -ForegroundColor Yellow
    $Repo = Read-Host "Enter repository (e.g. owner/repo-name)"
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Host "No repository provided. Exiting." -ForegroundColor Red
    exit 1
}

# === Detect Workflows from .github/workflows (safe) ===
$Workflows = @()
$WorkflowsPath = Join-Path -Path (Get-Location) -ChildPath ".github\workflows"

if (Test-Path $WorkflowsPath) {
    $Workflows = Get-ChildItem -Path $WorkflowsPath -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -in ".yml", ".yaml" } |
                 Select-Object -ExpandProperty Name
}

if ($Workflows.Count -gt 0) {
    Write-Host "`nFound workflows in .github/workflows:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Workflows.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Workflows[$i])
    }
    Write-Host ""

    $choice = Read-Host "Enter workflow number or filename (e.g. 1 or ci.yml)"

    if ($choice -match '^\d+$') {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $Workflows.Count) {
            $Workflow = $Workflows[$index]
        } else {
            Write-Host "Invalid number. Exiting." -ForegroundColor Red
            exit 1
        }
    } else {
        $Workflow = $choice
    }
} else {
    Write-Host "No workflow files found in .github/workflows (or not in a repo folder)." -ForegroundColor Yellow
    $Workflow = Read-Host "Enter the workflow filename (e.g. ci.yml or bw-click-classic.yml)"
}

if ([string]::IsNullOrWhiteSpace($Workflow)) {
    Write-Host "No workflow name provided. Exiting." -ForegroundColor Red
    exit 1
}

# === Confirm and Delete ===
Write-Host "`nDeleting all runs for workflow '$Workflow' in repo '$Repo'" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel at any time.`n"

while ($true) {
    $ids = gh run list --repo $Repo --workflow $Workflow --limit 1000 --json databaseId 2>$null | ConvertFrom-Json | ForEach-Object { $_.databaseId }

    if (-not $ids -or $ids.Count -eq 0) {
        Write-Host "No more runs found for workflow '$Workflow'. Done." -ForegroundColor Green
        break
    }

    Write-Host "Found $($ids.Count) runs. Deleting..." -ForegroundColor Cyan

    foreach ($id in $ids) {
        Write-Host "Deleting run $id"
        gh run delete $id --repo $Repo
    }
}