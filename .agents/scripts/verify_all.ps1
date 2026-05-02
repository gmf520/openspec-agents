# verify_all.ps1 - 全量验证脚本
# 用途: 由 Verify Agent 调用，执行编译、lint、格式、安全等全面检查
# 返回: $LASTEXITCODE = 0 表示全部通过，非0表示有失败项

param(
    [string]$ChangeName = "",
    [switch]$SkipSecurity = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"
$global:TotalChecks = 0
$global:PassedChecks = 0
$global:FailedChecks = 0
$global:CheckResults = @()

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-CheckResult {
    param(
        [string]$CheckName,
        [bool]$Passed,
        [string]$Detail = ""
    )
    $global:TotalChecks++
    if ($Passed) {
        $global:PassedChecks++
        Write-Host "  ✅ $CheckName" -ForegroundColor Green
        if ($Detail -and $Verbose) {
            Write-Host "     $Detail" -ForegroundColor DarkGray
        }
    } else {
        $global:FailedChecks++
        Write-Host "  ❌ $CheckName" -ForegroundColor Red
        if ($Detail) {
            Write-Host "     $Detail" -ForegroundColor Red
        }
    }
    $global:CheckResults += @{
        Name = $CheckName
        Passed = $Passed
        Detail = $Detail
    }
}

# ============================================================
# 1. 编译检查
# ============================================================
Write-Step "1. 编译检查"

# 检测项目类型
if (Test-Path "package.json") {
    $projectType = "node"
} elseif (Test-Path "Cargo.toml") {
    $projectType = "rust"
} elseif (Test-Path "go.mod") {
    $projectType = "go"
} elseif (Test-Path "pom.xml") {
    $projectType = "maven"
} elseif (Test-Path "build.gradle" -or (Test-Path "build.gradle.kts")) {
    $projectType = "gradle"
} elseif (Test-Path "requirements.txt" -or (Test-Path "pyproject.toml") -or (Test-Path "setup.py")) {
    $projectType = "python"
} else {
    $projectType = "unknown"
}

Write-Host "检测到项目类型: $projectType"

switch ($projectType) {
    "node" {
        # TypeScript 编译检查
        $tsconfigExists = Test-Path "tsconfig.json"
        if ($tsconfigExists) {
            Write-Host "运行 TypeScript 编译检查..."
            $result = npx tsc --noEmit 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "TypeScript 编译" $passed ($result -join "`n")
        } else {
            Write-CheckResult "TypeScript 编译" $true "无 tsconfig.json，跳过"
        }
    }
    "rust" {
        Write-Host "运行 Rust 编译检查..."
        $result = cargo check 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Rust 编译" $passed ($result -join "`n")
    }
    "go" {
        Write-Host "运行 Go 编译检查..."
        $result = go build ./... 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Go 编译" $passed ($result -join "`n")
    }
    "maven" {
        Write-Host "运行 Maven 编译检查..."
        $result = mvn compile 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Maven 编译" $passed ($result -join "`n")
    }
    "gradle" {
        Write-Host "运行 Gradle 编译检查..."
        $result = ./gradlew compileJava 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Gradle 编译" $passed ($result -join "`n")
    }
    "python" {
        Write-Host "运行 Python 语法检查..."
        $result = python -m compileall -q . 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Python 语法" $passed ($result -join "`n")
    }
    default {
        Write-CheckResult "编译检查" $true "未识别的项目类型，跳过编译检查"
    }
}

# ============================================================
# 2. Lint 检查
# ============================================================
Write-Step "2. Lint 检查"

switch ($projectType) {
    "node" {
        $eslintExists = Test-Path "node_modules/.bin/eslint"
        if ($eslintExists) {
            $result = npx eslint . --ext .ts,.tsx,.js,.jsx --max-warnings 0 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "ESLint" $passed ($result -join "`n")
        }
        $prettierExists = Test-Path "node_modules/.bin/prettier"
        if ($prettierExists) {
            $result = npx prettier --check "**/*.{ts,tsx,js,jsx,json,md}" 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "Prettier 格式" $passed ($result -join "`n")
        }
        if (-not $eslintExists -and -not $prettierExists) {
            Write-CheckResult "Lint 检查" $true "未配置 ESLint/Prettier，跳过"
        }
    }
    "rust" {
        $result = cargo clippy -- -D warnings 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Clippy" $passed ($result -join "`n")
        
        $result = cargo fmt --check 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "Rustfmt" $passed ($result -join "`n")
    }
    "go" {
        $result = go vet ./... 2>&1
        $passed = ($LASTEXITCODE -eq 0)
        Write-CheckResult "go vet" $passed ($result -join "`n")
    }
    "python" {
        $flake8Exists = Get-Command flake8 -ErrorAction SilentlyContinue
        if ($flake8Exists) {
            $result = flake8 . 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "Flake8" $passed ($result -join "`n")
        } else {
            Write-CheckResult "Lint 检查" $true "未配置 flake8，跳过"
        }
    }
}

# ============================================================
# 3. 依赖审计
# ============================================================
Write-Step "3. 依赖审计"

if (-not $SkipSecurity) {
    switch ($projectType) {
        "node" {
            $result = npm audit --audit-level=high 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "npm audit" $passed ($result -join "`n")
        }
        "rust" {
            $result = cargo audit 2>&1
            $passed = ($LASTEXITCODE -eq 0)
            Write-CheckResult "cargo audit" $passed ($result -join "`n")
        }
        "python" {
            $pipAuditExists = Get-Command pip-audit -ErrorAction SilentlyContinue
            if ($pipAuditExists) {
                $result = pip-audit 2>&1
                $passed = ($LASTEXITCODE -eq 0)
                Write-CheckResult "pip-audit" $passed ($result -join "`n")
            } else {
                Write-CheckResult "依赖审计" $true "未安装 pip-audit，跳过"
            }
        }
        default {
            Write-CheckResult "依赖审计" $true "项目类型不支持自动审计"
        }
    }
} else {
    Write-CheckResult "依赖审计" $true "已跳过（--SkipSecurity）"
}

# ============================================================
# 4. 文件完整性检查
# ============================================================
Write-Step "4. 文件完整性检查"

# 检查是否有临时文件残留
$tempFiles = @(
    Get-ChildItem -Recurse -Filter "*.tmp" -ErrorAction SilentlyContinue,
    Get-ChildItem -Recurse -Filter "*.bak" -ErrorAction SilentlyContinue,
    Get-ChildItem -Recurse -Filter "*~" -ErrorAction SilentlyContinue
) | Where-Object { $_ -ne $null }

$noTempFiles = ($tempFiles.Count -eq 0)
Write-CheckResult "无临时文件残留" $noTempFiles ($tempFiles -join ", ")

# 检查 .gitignore 是否存在
$gitignoreExists = Test-Path ".gitignore"
Write-CheckResult ".gitignore 存在" $gitignoreExists

# ============================================================
# 5. OpenSpec 验证
# ============================================================
Write-Step "5. OpenSpec 验证"

if ($ChangeName) {
    $result = openspec verify --change $ChangeName 2>&1
    $passed = ($LASTEXITCODE -eq 0)
    Write-CheckResult "openspec verify: $ChangeName" $passed ($result -join "`n")
} else {
    $result = openspec validate 2>&1
    $passed = ($LASTEXITCODE -eq 0)
    Write-CheckResult "openspec validate" $passed ($result -join "`n")
}

# ============================================================
# 汇总
# ============================================================
Write-Step "验证汇总"

Write-Host ""
Write-Host "总检查项: $TotalChecks" -ForegroundColor White
Write-Host "通过: $PassedChecks" -ForegroundColor Green
Write-Host "失败: $FailedChecks" -ForegroundColor $(if ($FailedChecks -gt 0) { "Red" } else { "Green" })
Write-Host "通过率: $([math]::Round($PassedChecks / $TotalChecks * 100, 1))%" -ForegroundColor $(if ($FailedChecks -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($FailedChecks -gt 0) {
    Write-Host "失败项详情:" -ForegroundColor Red
    foreach ($check in $global:CheckResults) {
        if (-not $check.Passed) {
            Write-Host "  ❌ $($check.Name)" -ForegroundColor Red
            if ($check.Detail) {
                Write-Host "     $($check.Detail)" -ForegroundColor DarkRed
            }
        }
    }
    exit 1
} else {
    Write-Host "🎉 所有验证通过!" -ForegroundColor Green
    exit 0
}
