# compile_check.ps1 - 编译检查脚本
# 用途: 由 Apply Agent 在每个任务完成后调用，确保代码可编译
# 返回: $LASTEXITCODE = 0 表示编译通过，非0表示有错误

param(
    [switch]$Quick = $false  # 快速模式：仅检查语法，不生成产物
)

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  编译检查" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 检测项目类型
if (Test-Path "package.json") {
    $projectType = "node"
}
elseif (Test-Path "Cargo.toml") {
    $projectType = "rust"
}
elseif (Test-Path "go.mod") {
    $projectType = "go"
}
elseif (Test-Path "pom.xml") {
    $projectType = "maven"
}
elseif (Test-Path "build.gradle" -or (Test-Path "build.gradle.kts")) {
    $projectType = "gradle"
}
elseif (Test-Path "requirements.txt" -or (Test-Path "pyproject.toml") -or (Test-Path "setup.py")) {
    $projectType = "python"
}
else {
    Write-Host "⚠️  未检测到已知项目类型，尝试通用检查..." -ForegroundColor Yellow
    $projectType = "unknown"
}

Write-Host "项目类型: $projectType"
Write-Host ""

switch ($projectType) {
    "node" {
        $tsconfigExists = Test-Path "tsconfig.json"
        if ($tsconfigExists) {
            Write-Host "🔨 TypeScript 编译检查..." -ForegroundColor White
            $result = npx tsc --noEmit 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Host "✅ TypeScript 编译通过" -ForegroundColor Green
            }
            else {
                Write-Host "❌ TypeScript 编译失败:" -ForegroundColor Red
                $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            }
        }
        else {
            Write-Host "ℹ️  未找到 tsconfig.json，跳过 TypeScript 检查" -ForegroundColor Yellow
            
            # 尝试 JavaScript 语法检查
            $jsFiles = Get-ChildItem -Recurse -Filter "*.js" -Exclude "node_modules" -ErrorAction SilentlyContinue
            if ($jsFiles) {
                Write-Host "🔨 JavaScript 语法检查..." -ForegroundColor White
                $hasError = $false
                foreach ($file in $jsFiles) {
                    $result = node --check $file.FullName 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $hasError = $true
                        Write-Host "❌ $($file.Name): $result" -ForegroundColor Red
                    }
                }
                if (-not $hasError) {
                    Write-Host "✅ JavaScript 语法检查通过" -ForegroundColor Green
                }
                $exitCode = if ($hasError) { 1 } else { 0 }
            }
            else {
                Write-Host "ℹ️  无 JavaScript 文件，编译检查通过" -ForegroundColor Yellow
                $exitCode = 0
            }
        }
    }
    "rust" {
        Write-Host "🔨 Rust 编译检查..." -ForegroundColor White
        $checkCmd = if ($Quick) { "cargo check" } else { "cargo check" }
        $result = Invoke-Expression $checkCmd 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Rust 编译通过" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Rust 编译失败:" -ForegroundColor Red
            $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    "go" {
        Write-Host "🔨 Go 编译检查..." -ForegroundColor White
        $result = go build ./... 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Go 编译通过" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Go 编译失败:" -ForegroundColor Red
            $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    "maven" {
        Write-Host "🔨 Maven 编译检查..." -ForegroundColor White
        $result = mvn compile -q 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Maven 编译通过" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Maven 编译失败:" -ForegroundColor Red
            $result | Select-Object -Last 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    "gradle" {
        Write-Host "🔨 Gradle 编译检查..." -ForegroundColor White
        $gradleCmd = if (Test-Path "gradlew") { "./gradlew" } elseif (Test-Path "gradlew.bat") { "gradlew.bat" } else { "gradle" }
        $result = & $gradleCmd compileJava -q 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Gradle 编译通过" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Gradle 编译失败:" -ForegroundColor Red
            $result | Select-Object -Last 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    "python" {
        Write-Host "🔨 Python 语法检查..." -ForegroundColor White
        $result = python -m compileall -q . 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Python 语法检查通过" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Python 语法检查失败:" -ForegroundColor Red
            $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    default {
        Write-Host "⚠️  无法确定编译命令，跳过编译检查" -ForegroundColor Yellow
        "dotnet" {
            Write-Host "🔨 .NET 编译检查..." -ForegroundColor White
            $dotnetCmd = if ($Quick) { "dotnet build --no-restore" } else { "dotnet build" }
            $result = Invoke-Expression $dotnetCmd 2>&1
            $exitCode = $LASTEXITCODE
        
            if ($exitCode -eq 0) {
                Write-Host "✅ .NET 编译通过" -ForegroundColor Green
            }
            else {
                Write-Host "❌ .NET 编译失败:" -ForegroundColor Red
                $result | Select-Object -Last 30 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            }
        }
        $exitCode = 0
    }
}

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host "  编译检查: PASS" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
}
else {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  编译检查: FAIL ($exitCode)" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
}

exit $exitCode

exit $exitCode
