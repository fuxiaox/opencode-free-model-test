<div align="center">

# OpenCode 免费模型测试报告

**基于连通稳定性 · 响应延迟 · 工具调用 · 代码生成 的横评实测**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![OpenCode](https://img.shields.io/badge/OpenCode-v2.0.32-3b82f6)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20PowerShell-lightgrey)
![Updated](https://img.shields.io/badge/updated-2026--10--19-blue)

</div>

> 📊 **可视化报告**：打开 [`index.html`](index.html) —— 本地浏览器直接查看，支持暗色模式与响应式布局
>
> 🧪 **可复现**：全部数据由 [`bench.ps1`](bench.ps1) 自动产出，非人工誊写

---

## TL;DR

<div align="center">

| 🏆 当前推荐 | 稳定性 | 中位延迟 | 能力项 |
|:--|:--:|:--:|:--:|
| **`opencode/minimax-m3.1-flash-free`** | **7 / 7** | **10.1s** | **3 / 3** |

</div>

- 速度为第二名的 **1/2**，延迟振幅 **6.6s**（6.3 ~ 12.9s）为全榜最集中
- 工具调用、推理、代码三项全部通过，累计 7 轮无失败
- ⚠️ **免费模型阵容在滚动轮换**——本仓库的排名有时效性，选用前请复测

---

## 📋 目录

- [当前可用模型完整榜单](#-当前可用模型完整榜单)
- [关键发现：免费阵容在轮换](#-关键发现免费阵容在轮换)
- [测试方法](#-测试方法)
- [前一日快照（观察轮换）](#-前一日快照观察轮换)
- [不可用模型及原因](#-不可用模型及原因)
- [选型建议](#-选型建议)
- [快速开始](#-快速开始)
- [文件清单](#-文件清单)
- [免责声明](#-免责声明)

---

## 📊 当前可用模型完整榜单

> 采样时间 **2026-10-19**，同一时段统一执行，题目与判定标准完全一致。

| 模型 | 上架日期 | 稳定性 | 平均 | 中位 | 最小 | 最大 | 质量题 |
|---|:---:|:---:|---:|---:|---:|---:|:---:|
| **[`minimax-m3.1-flash-free`](index.html)** | 2026-10-19 | **5/5** | **10.1s** | **10.1s** | 6.3s | **12.9s** | ✅ 6.5s |
| `deepseek-v4.1-flash-free` | 2026-09-10 | 5/5 | 22.5s | 19.2s | 10.6s | 47.9s | ✅ 4.9s |
| `big-pickle` | 2025-10-17 | 3/3 | 22.5s | 23.9s | 18.9s | 24.7s | ✅ 7.6s |
| `mimo-v2.6-flash-free` | 2026-09-22 | 3/3 | 24.9s | 24.7s | 14.1s | 35.9s | ✅ 19.8s |
| `longcat-2.5-preview-free` | 2026-09-25 | 2/3 | 26.1s | 16.5s | 15.6s | 46.1s | ✅ 10.1s |
| `glm-5.3-flash-free` | 2026-08-26 | 3/3 | 31.0s | 31.5s | 8.6s | 52.8s | ✅ 39.5s |
| `nemotron-3.5-super-vl-free` | 2026-10-15 | 3/3 | 42.6s | 44.0s | 14.7s | 69.1s | ✅ 28.0s |
| `beam-free` | 2026-10-05 | ❌ 地区封锁 | — | — | — | — | — |
| `space-bunny-free` | — | ❌ 已下架 | — | — | — | — | — |

> 附加验证：`minimax-m3.1-flash-free` 于 22:21 另跑 2 轮，2/2 通过，中位 7.3s，区间 6.7~7.3s —— 累计 **7/7 无失败**。

---

## 🔄 关键发现：免费阵容在轮换

| 变化 | 模型 | 说明 |
|:---:|---|---|
| ➕ | `minimax-m3.1-flash-free` | 2026-10-19 上线，即本次测试的「当前模型」 |
| ➖ | `space-bunny-free` | 10-18 尚可用且速度最快，10-19 已返回 `Model unavailable` |

> ⚠️ **任何免费模型排名都有时效性。** 本次首轮结论「space-bunny-free 最快」在次日即失效。免费档模型滚动换血，建议每隔一段时间复测。

---

## 🧪 测试方法

### 总体思路

以 `opencode run` 作为统一调用入口（非交互模式，与 TUI 走同一套 provider 链路），对每个模型施加**完全相同**的题目，记录各维度指标：

| 维度 | 观测指标 |
|---|---|
| 连通稳定性 | 连续 N 轮中完全通过的轮数（pass rate） |
| 响应延迟 | 每轮端到端耗时：平均 / 中位 / 最小 / 最大 |
| 工具调用 | 是否真正调用 `read` 工具读出夹具文件中的密钥 |
| 推理能力 | 注水池多步算术题是否得出正确答案 |
| 代码生成 | 是否给出可用的函数实现；是否满足复杂度要求 |

### 题目 A —— 标准题（工具调用 + 推理 + 代码，三合一）

```text
Read MODEL_TEST_FIXTURE.md and report the value after SECRET_CODE:.
Answer: two pipes fill a pool, A takes 6 hours, B takes 4 hours, both together how many hours?
Write a one-line JS function isPrime(n).
Output three lines: SECRET=<value>, HOURS=<number>, CODE=<fn>
```

配套夹具文件 [`MODEL_TEST_FIXTURE.md`](MODEL_TEST_FIXTURE.md)，内含唯一标记：

```text
SECRET_CODE: ZX-9137-QQ
```

三项判定（`pass` = 三项全中）：

| 字段 | 判定正则 | 考察点 |
|---|---|---|
| `secret` | 输出含 `ZX-9137-QQ` | **工具调用**：必须真的用 `read` 打开文件才能拿到值，无法靠猜 |
| `hours` | `HOURS[:=] 2.4`（或 `12/5`） | **多步推理**：1/6 + 1/4 = 5/12 → 12/5 = 2.4 小时 |
| `code` | 输出含 `isPrime` | **代码生成** |

### 题目 B —— 质量题（算法题）

```text
Write a JavaScript function longestIncreasingSubsequence(arr) returning the length of
the longest strictly increasing subsequence, O(n log n).
Then answer: what does longestIncreasingSubsequence([10,9,2,5,3,7,101,18]) return?
Output exactly two lines: ANSWER=<number> and CODE=<the function>
```

- 标准答案 `ANSWER=4`（例如 `2,3,7,18`）
- `codeOk`：代码含 `function` 或 `=>`，且含 `bisect|lower_bound|tails|push|splice|sort` 之一
- **正则未命中时一律人工复核实际代码** —— 本次对 space-bunny / nemotron / glm 三例做了人工复核，均为正确实现，判定为正则误报

### 稳定性测试协议

- 每个模型连续执行 N 轮同一道题（N = 5 为主，部分模型 N = 3）
- 记录逐轮耗时数组，统计 **pass 数、平均值、中位数、最小值、最大值**
- 中位数优先于平均值：免费档存在偶发长尾，均值容易被单次冷启动 / 排队拉偏
- **首轮存在冷启动**（实测首次调用可达 85s+），故以中位数与多次采样为准

### 计时与判读实现

```powershell
# 计时：包裹子进程调用
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$stdout = (& opencode run --model $Model $PROMPT 2>&1 | Out-String)
$sw.Stop()
$ms = [int]$sw.Elapsed.TotalMilliseconds

# 判读：剥离 ANSI 控制序列与非 ASCII 字符后正则匹配
($s -replace "`e\[[0-9;]*[mK]", "") -replace "[^\x20-\x7E]", " "
```

### 方法局限性

1. **单时段快照** —— 免费档延迟随平台负载剧烈波动，跨时段差异可达数倍，结论仅代表采样时刻。
2. **样本量有限** —— 每模型 3~5 轮，只能发现明显的稳定性问题，无法刻画长尾概率。
3. **题目偏简单** —— 标准题所有可用模型均满分，未能拉开差距；区分度主要来自延迟与稳定性。
4. **判定用正则启发式** —— 代码质量未做人工逐行评审，可能漏判风格问题或同解不同写法。
5. **未覆盖** —— 超长上下文、视觉输入、工具并发、流式中断恢复、token 配额约束。

---

## 📅 前一日快照（观察轮换）

> 采样时间 **2026-10-18**，用于与上表对比。

| 模型 | 稳定性 | 平均 | 中位 | 最小 | 最大 | 备注 |
|---|:---:|---:|---:|---:|---:|---|
| `space-bunny-free` | 5/5 | 6.4s | 5.0s | 4.2s | 11.2s | **当时最快，次日已下架** |
| `deepseek-v4.1-flash-free` | 5/5 | 8.4s | 8.5s | 7.2s | 10.4s | 当时延迟最集中 |
| `longcat-2.5-preview-free` | 5/5 | 14.5s | 12.9s | 11.9s | 17.8s | |
| `big-pickle` | 5/5 | 17.4s | 15.1s | 11.8s | 31.3s | |
| `nemotron-3.5-super-vl-free` | 5/5 | 39.6s | 32.8s | 11.3s | 85.4s | |
| `mimo-v2.6-flash-free` | 5/5 | 54.3s | 19.9s | 10.4s | 137.1s | 长尾极严重 |
| `glm-5.3-flash-free` | **4/5** | 32.9s | 27.8s | 16.1s | 63.5s | 有 1 轮失败 |

> 同模型跨日对比可见平台负载影响：`deepseek-v4.1-flash-free` 中位由 8.5s 变为 19.2s，`mimo-v2.6-flash-free` 平均由 54.3s 变为 24.9s。

---

## ❌ 不可用模型及原因

### A. `beam-free` —— 地区限制

```text
Error: This model is not available in your country
```

官方文档列明该模型在部分国家 / 地区不可用，当前网络环境位于受限范围。

### B. `space-bunny-free` —— 已从模型目录移除

客户端直接返回 `Model unavailable`（<1s 拒绝，非超时），属目录层面移除而非服务故障。

---

## 🎯 选型建议

| 场景 | 推荐 | 理由 |
|---|---|---|
| **默认模型** | `opencode/minimax-m3.1-flash-free` | 速度、稳定性、能力三项综合最优；7/7 无失败 |
| 追求最快响应 | `opencode/minimax-m3.1-flash-free` | 中位 10.1s，无更快的在架模型 |
| 长文档 / 长上下文 | `opencode/longcat-2.5-preview-free` | 主打长上下文，但需接受 2/3 的稳定性 |
| 多模态（看图） | `opencode/nemotron-3.5-super-vl-free` | 唯一在架的 VL 模型，代价是 44s 中位延迟 |
| 规避 | `glm-5.3-flash-free`、`mimo-v2.6-flash-free` | 前者曾出现轮次失败，后者长尾达 137s |

落地方案：

```jsonc
// ~/.config/opencode/opencode.jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/minimax-m3.1-flash-free"
}
```

---

## 🚀 快速开始

```powershell
# 克隆后进入目录（脚本依赖同目录的夹具文件）
cd opencode-free-model-test

# 单个模型：5 轮稳定性 + 1 轮质量
.\bench.ps1 -Model "opencode/minimax-m3.1-flash-free" -N 5

# 批量对比
.\bench.ps1 -Models "opencode/deepseek-v4.1-flash-free,opencode/big-pickle" -N 5

# 查看当前免费模型目录
opencode models
```

脚本输出为可解析的管道分隔格式，便于二次处理：

```text
STAB|<model>|pass=5/5|secret=5/5|hours=5/5|code=5/5|avgMs=10121|medMs=10147|min=6328|max=12941|times=...
QUAL|<model>|answerIs4=True|codeOk=True|pass=True|ms=6470
```

---

## 📁 文件清单

| 文件 | 说明 |
|---|---|
| [`README.md`](README.md) | 本报告（Markdown 版） |
| [`index.html`](index.html) | 本报告（HTML 版，支持暗色模式，可直接浏览器打开） |
| [`bench.ps1`](bench.ps1) | 基准测试脚本（稳定性 + 质量双测试） |
| [`MODEL_TEST_FIXTURE.md`](MODEL_TEST_FIXTURE.md) | 测试夹具，内含用于校验工具调用能力的唯一标记 |

---

## ⚠️ 免责声明

测试结论基于特定时间点的采样，免费模型阵容与延迟会随平台调整而变化，**选型前建议按 [`bench.ps1`](bench.ps1) 复测**。本仓库仅记录实测数据，不构成任何使用承诺。

---

## 📄 License

[MIT](LICENSE) © 2026 Brett
