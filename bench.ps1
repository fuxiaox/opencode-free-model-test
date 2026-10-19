<#
.SYNOPSIS
    OpenCode 免费模型基准测试脚本。

.DESCRIPTION
    对指定模型执行两类测试并输出可解析的结果行：

    1) 稳定性+能力测试（标准题，重复 N 轮）
       同一道题同时考察三项能力：
         - secret : 是否通过 read 工具读到夹具文件中的密钥（工具调用能力）
         - hours  : 注水池推理题答案是否为 2.4（多步算术推理）
         - code   : 是否给出 isPrime 函数（代码生成）
       pass = 三项全部命中。

    2) 质量测试（算法题，1 轮）
       最长递增子序列（LIS），标准答案 4，要求 O(n log n) 实现。
       codeOk 为正则启发式判定，未命中时需人工复核实际代码。

    计时方式：用 System.Diagnostics.Stopwatch 包裹子进程调用，统计 TotalMilliseconds。
    判读方式：剥离 ANSI 控制序列与非 ASCII 字符后做正则匹配。

.EXAMPLE
    .\bench.ps1 -Model "opencode/minimax-m3.1-flash-free" -N 5
    .\bench.ps1 -Models "opencode/a,opencode/b" -N 3
#>
param(
    [string]$Model  = "",
    [string]$Models = "",
    [int]$N = 5,
    [switch]$SkipQuality
)

$ErrorActionPreference = "Continue"

# ---- 测试夹具必须与脚本同目录 ----
$Fixture = Join-Path $PSScriptRoot "MODEL_TEST_FIXTURE.md"

$PROMPT = 'Read MODEL_TEST_FIXTURE.md and report the value after SECRET_CODE:. Answer: two pipes fill a pool, A takes 6 hours, B takes 4 hours, both together how many hours? Write a one-line JS function isPrime(n). Output three lines: SECRET=<value>, HOURS=<number>, CODE=<fn>'

$QPROMPT = 'Write a JavaScript function longestIncreasingSubsequence(arr) returning the length of the longest strictly increasing subsequence, O(n log n). Then answer: what does longestIncreasingSubsequence([10,9,2,5,3,7,101,18]) return? Output exactly two lines: ANSWER=<number> and CODE=<the function>'

function Strip-Ansi([string]$s) {
    if ($null -eq $s) { return "" }
    return ($s -replace "`e\[[0-9;]*[mK]", "") -replace "[^\x20-\x7E]", " "
}

function Invoke-Model([string]$m, [string]$p) {
    $stdout = ""
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try { $stdout = (& opencode run --model $m $p 2>&1 | Out-String) }
    catch { $stdout = "EXCEPTION $_" }
    $sw.Stop()
    [pscustomobject]@{ ms = [int]$sw.Elapsed.TotalMilliseconds; clean = (Strip-Ansi $stdout) }
}

function Test-Stability([string]$m, [int]$n) {
    $times = @(); $nOk = 0; $s = 0; $h = 0; $c = 0; $err = ""
    for ($i = 1; $i -le $n; $i++) {
        $r = Invoke-Model $m $PROMPT
        $hasSecret = $r.clean -match "ZX-9137-QQ"
        $hasHours  = $r.clean -match "HOURS\s*[:=]\s*(2\.4|12/5|2\.40)"
        $hasCode   = $r.clean -match "isPrime"
        if ($hasSecret) { $s++ }; if ($hasHours) { $h++ }; if ($hasCode) { $c++ }
        if ($hasSecret -and $hasHours -and $hasCode) { $nOk++ }
        elseif (-not $err) { $err = ($r.clean -replace "\s+", " ") }
        $times += $r.ms
    }
    $sorted = $times | Sort-Object
    $med = [int]$sorted[[Math]::Floor($sorted.Count / 2)]
    $avg = [int](($times | Measure-Object -Average).Average)
    Write-Output ("STAB|$m|pass=$nOk/$n|secret=$s/$n|hours=$h/$n|code=$c/$n|avgMs=$avg|medMs=$med|min=" + ($times | Measure-Object -Minimum).Minimum + "|max=" + ($times | Measure-Object -Maximum).Maximum + "|times=" + ($times -join ","))
    if ($nOk -lt $n -and $err) {
        Write-Output ("  ERR|" + $err.Substring(0, [Math]::Min(160, $err.Length)))
    }
}

function Test-Quality([string]$m) {
    $r = Invoke-Model $m $QPROMPT
    $hasAns = $r.clean -match "ANSWER\s*[:=]\s*4\b"
    $hasFn  = ($r.clean -match "(function|=>)") -and ($r.clean -match "(bisect|lower_bound|tails|push|splice|sort)")
    Write-Output ("QUAL|$m|answerIs4=$hasAns|codeOk=$hasFn|pass=" + ($hasAns -and $hasFn) + "|ms=" + $r.ms)
}

# ---- 主流程 ----
if (-not (Test-Path $Fixture)) {
    Write-Error "缺少测试夹具 $Fixture"
    exit 1
}

$list = @()
if ($Models) { $list = $Models -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
elseif ($Model) { $list = @($Model) }
else { Write-Error "请用 -Model 或 -Models 指定模型"; exit 1 }

Write-Output ("# fixture=" + $Fixture + "  runs=" + $N + "  at=" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
foreach ($m in $list) {
    Test-Stability $m $N
    if (-not $SkipQuality) { Test-Quality $m }
}
