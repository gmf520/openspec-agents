# gate_review.ps1 - 闸门审查辅助脚本
# 用途: 由 Gate Review Agent 调用，自动检查规划制品的完整性
# 返回: 输出 JSON 格式的检查结果

param(
    [Parameter(Mandatory=$true)]
    [string]$ChangeName,
    
    [string]$ChangeDir = "openspec/changes/$ChangeName",
    [string]$DocsDir = "docs/features/$ChangeName"
)

$ErrorActionPreference = "Continue"

$results = @{
    change_name = $ChangeName
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    checks = @()
    summary = @{
        total = 0
        passed = 0
        failed = 0
        warnings = 0
    }
}

function Add-Check {
    param(
        [string]$Name,
        [string]$Category,
        [bool]$Passed,
        [string]$Detail = "",
        [string]$Severity = "error"  # "error" or "warning"
    )
    $results.summary.total++
    if ($Passed) {
        $results.summary.passed++
    } elseif ($Severity -eq "warning") {
        $results.summary.warnings++
    } else {
        $results.summary.failed++
    }
    $results.checks += @{
        name = $Name
        category = $Category
        passed = $Passed
        detail = $Detail
        severity = $Severity
    }
}

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  闸门审查辅助检查: $ChangeName" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 文件存在性检查
# ============================================================
Write-Host "--- 文件存在性检查 ---" -ForegroundColor Yellow

$requiredFiles = @(
    @{Path="$ChangeDir/proposal.md"; Name="proposal.md"},
    @{Path="$ChangeDir/design.md"; Name="design.md"},
    @{Path="$ChangeDir/tasks.md"; Name="tasks.md"}
)

foreach ($file in $requiredFiles) {
    $exists = Test-Path $file.Path
    $nonEmpty = if ($exists) { (Get-Content $file.Path -Raw).Trim().Length -gt 0 } else { $false }
    Add-Check -Name $file.Name -Category "文件存在性" -Passed ($exists -and $nonEmpty) `
        -Detail $(if (-not $exists) { "文件不存在" } elseif (-not $nonEmpty) { "文件为空" } else { "OK" })
}

# 检查 specs 目录
$specsExists = Test-Path "$ChangeDir/specs"
$specsNonEmpty = if ($specsExists) { (Get-ChildItem "$ChangeDir/specs" -Recurse -Filter "*.md").Count -gt 0 } else { $false }
Add-Check -Name "specs/ 目录" -Category "文件存在性" -Passed $specsNonEmpty `
    -Detail $(if (-not $specsExists) { "目录不存在" } elseif (-not $specsNonEmpty) { "无 spec 文件" } else { "包含 spec 文件" })

# 检查前置文档（REQ-01, DES-02）
$reqExists = Test-Path "$DocsDir/REQ-01_requirement_analysis.md"
Add-Check -Name "REQ-01 需求分析" -Category "文件存在性" -Passed $reqExists `
    -Detail $(if ($reqExists) { "OK" } else { "文件不存在" }) -Severity "warning"

$desExists = Test-Path "$DocsDir/DES-02_solution_design.md"
Add-Check -Name "DES-02 方案设计" -Category "文件存在性" -Passed $desExists `
    -Detail $(if ($desExists) { "OK" } else { "文件不存在" }) -Severity "warning"

# ============================================================
# 2. proposal.md 内容检查
# ============================================================
Write-Host "--- proposal.md 内容检查 ---" -ForegroundColor Yellow

if (Test-Path "$ChangeDir/proposal.md") {
    $proposalContent = Get-Content "$ChangeDir/proposal.md" -Raw
    
    $hasIntent = $proposalContent -match "Intent|意图"
    Add-Check -Name "proposal: Intent 章节" -Category "proposal.md" -Passed $hasIntent
    
    $hasScope = $proposalContent -match "Scope|范围"
    Add-Check -Name "proposal: Scope 章节" -Category "proposal.md" -Passed $hasScope
    
    $hasApproach = $proposalContent -match "Approach|方法"
    Add-Check -Name "proposal: Approach 章节" -Category "proposal.md" -Passed $hasApproach
}

# ============================================================
# 3. design.md 内容检查
# ============================================================
Write-Host "--- design.md 内容检查 ---" -ForegroundColor Yellow

if (Test-Path "$ChangeDir/design.md") {
    $designContent = Get-Content "$ChangeDir/design.md" -Raw
    
    $hasArchitecture = $designContent -match "Architecture|架构"
    Add-Check -Name "design: Architecture 章节" -Category "design.md" -Passed $hasArchitecture
    
    $hasComponent = $designContent -match "Component|组件"
    Add-Check -Name "design: Component Design 章节" -Category "design.md" -Passed $hasComponent
}

# ============================================================
# 4. tasks.md 内容检查
# ============================================================
Write-Host "--- tasks.md 内容检查 ---" -ForegroundColor Yellow

if (Test-Path "$ChangeDir/tasks.md") {
    $tasksContent = Get-Content "$ChangeDir/tasks.md" -Raw
    
    # 检查是否有未完成的任务（所有都应该是 - [ ]）
    $totalTasks = ([regex]::Matches($tasksContent, "- \[[ x]\]")).Count
    $incompleteTasks = ([regex]::Matches($tasksContent, "- \[ \]")).Count
    $completeTasks = ([regex]::Matches($tasksContent, "- \[x\]")).Count
    
    Add-Check -Name "tasks: 有可执行任务" -Category "tasks.md" -Passed ($totalTasks -gt 0) `
        -Detail "总计: $totalTasks, 待执行: $incompleteTasks, 已完成: $completeTasks"
    
    # 检查任务是否原子化（每个任务应该简短）
    $taskLines = $tasksContent -split "`n" | Where-Object { $_ -match "- \[[ x]\]" }
    $longTasks = ($taskLines | Where-Object { $_.Length -gt 200 }).Count
    Add-Check -Name "tasks: 任务粒度合理" -Category "tasks.md" -Passed ($longTasks -eq 0) `
        -Detail $(if ($longTasks -gt 0) { "$longTasks 个任务描述过长（>$([int](200))字符）" } else { "所有任务描述简洁" }) `
        -Severity "warning"
}

# ============================================================
# 5. specs 内容检查
# ============================================================
Write-Host "--- specs 内容检查 ---" -ForegroundColor Yellow

if ($specsNonEmpty) {
    $specFiles = Get-ChildItem "$ChangeDir/specs" -Recurse -Filter "*.md"
    foreach ($specFile in $specFiles) {
        $specContent = Get-Content $specFile.FullName -Raw
        $hasScenarios = $specContent -match "Scenario|场景|GIVEN|WHEN|THEN"
        Add-Check -Name "specs: $($specFile.Name) 包含场景" -Category "specs" -Passed $hasScenarios `
            -Detail $(if ($hasScenarios) { "包含 Given-When-Then 场景" } else { "缺少场景定义" })
    }
}

# ============================================================
# 输出 JSON 结果
# ============================================================
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor $(if ($results.summary.failed -gt 0) { "Red" } else { "Green" })
Write-Host "  检查结果: $($results.summary.passed)/$($results.summary.total) 通过" -ForegroundColor $(if ($results.summary.failed -gt 0) { "Red" } else { "Green" })
Write-Host "  失败: $($results.summary.failed) | 警告: $($results.summary.warnings)" -ForegroundColor $(if ($results.summary.failed -gt 0) { "Red" } else { "Green" })
Write-Host "═══════════════════════════════════════" -ForegroundColor $(if ($results.summary.failed -gt 0) { "Red" } else { "Green" })

# 输出 JSON（供 Gate Review Agent 解析）
$results | ConvertTo-Json -Depth 3

exit $results.summary.failed
