# test_runner.ps1 - 测试运行脚本
# 用途: 由 Test Agent 调用，自动发现并运行项目测试
# 返回: $LASTEXITCODE = 0 表示全部测试通过，非0表示有失败

param(
    [string]$Filter = "",       # 过滤特定测试
    [switch]$Coverage = $false, # 生成覆盖率报告
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  测试执行" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 检测项目类型
if (Test-Path "package.json") {
    $projectType = "node"
    
    # 检测测试框架
    $packageJson = Get-Content package.json | ConvertFrom-Json
    $devDeps = if ($packageJson.devDependencies) { $packageJson.devDependencies.PSObject.Properties.Name } else { @() }
    $deps = if ($packageJson.dependencies) { $packageJson.dependencies.PSObject.Properties.Name } else { @() }
    $allDeps = $devDeps + $deps
    
    if ($allDeps -contains "vitest") {
        $testFramework = "vitest"
    }
    elseif ($allDeps -contains "jest") {
        $testFramework = "jest"
    }
    elseif ($allDeps -contains "mocha") {
        $testFramework = "mocha"
    }
    elseif ($packageJson.scripts -and $packageJson.scripts.test) {
        $testFramework = "npm-script"
    }
    else {
        $testFramework = "unknown"
    }
}
elseif (Test-Path "Cargo.toml") {
    $projectType = "rust"
    $testFramework = "cargo"
}
elseif (Test-Path "go.mod") {
    $projectType = "go"
    $testFramework = "go"
}
elseif (Test-Path "pom.xml") {
    $projectType = "maven"
    $testFramework = "maven"
}
elseif (Test-Path "build.gradle" -or (Test-Path "build.gradle.kts")) {
    $projectType = "gradle"
    $testFramework = "gradle"
}
elseif (Test-Path "requirements.txt" -or (Test-Path "pyproject.toml") -or (Test-Path "setup.py")) {
    $projectType = "python"
    # 检测 pytest
    $pipList = pip list 2>$null
    if ($pipList -match "pytest") {
        $testFramework = "pytest"
    }
    elseif ($pipList -match "unittest") {
        $testFramework = "unittest"
    }
    else {
        $testFramework = "python-unittest"
    }
}
else {
    $projectType = "unknown"
    $testFramework = "unknown"
}

Write-Host "项目类型: $projectType"
Write-Host "测试框架: $testFramework"
Write-Host ""

$startTime = Get-Date

switch ($testFramework) {
    "vitest" {
        Write-Host "🔨 运行 Vitest 测试..." -ForegroundColor White
        $cmd = "npx vitest run"
        if ($Filter) { $cmd += " -t `"$Filter`"" }
        if ($Coverage) { $cmd += " --coverage" }
        if ($Verbose) { $cmd += " --reporter verbose" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "jest" {
        Write-Host "🔨 运行 Jest 测试..." -ForegroundColor White
        $cmd = "npx jest"
        if ($Filter) { $cmd += " -t `"$Filter`"" }
        if ($Coverage) { $cmd += " --coverage" }
        if ($Verbose) { $cmd += " --verbose" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "mocha" {
        Write-Host "🔨 运行 Mocha 测试..." -ForegroundColor White
        $cmd = "npx mocha"
        if ($Filter) { $cmd += " --grep `"$Filter`"" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "npm-script" {
        Write-Host "🔨 运行 npm test..." -ForegroundColor White
        $cmd = "npm test"
        if ($Filter) { 
            Write-Host "⚠️  npm script 模式不支持 Filter 参数" -ForegroundColor Yellow 
        }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "cargo" {
        Write-Host "🔨 运行 Cargo 测试..." -ForegroundColor White
        $cmd = "cargo test"
        if ($Filter) { $cmd += " $Filter" }
        if ($Verbose) { $cmd += " -- --nocapture" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "go" {
        Write-Host "🔨 运行 Go 测试..." -ForegroundColor White
        $cmd = "go test ./..."
        if ($Filter) { $cmd += " -run `"$Filter`"" }
        if ($Verbose) { $cmd += " -v" }
        if ($Coverage) { $cmd += " -coverprofile=coverage.out" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "maven" {
        Write-Host "🔨 运行 Maven 测试..." -ForegroundColor White
        $cmd = "mvn test"
        if ($Filter) { $cmd += " -Dtest=`"$Filter`"" }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "gradle" {
        Write-Host "🔨 运行 Gradle 测试..." -ForegroundColor White
        $gradleCmd = if (Test-Path "gradlew") { "./gradlew" } elseif (Test-Path "gradlew.bat") { "gradlew.bat" } else { "gradle" }
        $cmd = "$gradleCmd test"
        if ($Filter) { $cmd += " --tests `"$Filter`"" }
        
        $result = & $gradleCmd test 2>&1
        $exitCode = $LASTEXITCODE
    }
    "pytest" {
        Write-Host "🔨 运行 pytest..." -ForegroundColor White
        $cmd = "python -m pytest"
        if ($Filter) { $cmd += " -k `"$Filter`"" }
        if ($Verbose) { $cmd += " -v" }
        if ($Coverage) { $cmd += " --cov=." }
        
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
    }
    "python-unittest" {
        Write-Host "🔨 运行 unittest..." -ForegroundColor White
        $result = python -m unittest discover -v 2>&1
        $exitCode = $LASTEXITCODE
    }
    default {
        Write-Host "⚠️  无法检测测试框架" -ForegroundColor Yellow
        Write-Host "请手动指定测试命令" -ForegroundColor Yellow
        "dotnet" {
            Write-Host "🔨 运行 .NET 测试..." -ForegroundColor White
            $cmd = "dotnet test"
            if ($Filter) { $cmd += " --filter `"$Filter`"" }
            if ($Verbose) { $cmd += " -v" }
            if ($Coverage) { $cmd += " --collect:`"XPlat Code Coverage`"" }
        
            $result = Invoke-Expression $cmd 2>&1
            $exitCode = $LASTEXITCODE
        }
        $exitCode = 1
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "⏱️  耗时: $([math]::Round($duration, 1))s" -ForegroundColor Gray
Write-Host ""

if ($exitCode -eq 0) {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host "  测试结果: ALL PASS" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
}
else {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  测试结果: FAIL ($exitCode)" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
}

exit $exitCode
}

exit $exitCode
