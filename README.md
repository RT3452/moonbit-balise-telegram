# moonbit-balise-telegram

MoonBit 地面应答器（Eurobalise / CTCS Balise）报文解析与数据链路仿真器。

这个项目面向车载 BTM 解码器、信号测试工具和铁路协议教学场景，提供一条可重复的测试链路：

`逻辑 Telegram → Packet 12/21/27/Linking → 10→11 信道成形 → 341/1023 bit 帧 → 校验 → 反向解析`

项目的目标不是实现射频接收机，而是把“位级协议、包级语义、应答器组顺序”拆成可组合的 MoonBit 库，方便上层测试和后续扩展。

## 现在能做什么

- `BitReader` / `BitWriter`：MSB-first 位流读取、定宽整数、切片、边界检查。
- Eurobalise 信道帧：短报文 341 bit、长报文 1023 bit；公开的 10→11 码本；85 bit Block Check；损坏帧拒绝。
- ETCS 包：Packet 5 Linking、Packet 12 Movement Authority、Packet 21 Gradient、Packet 27 Static Speed，以及未知包保留。
- Telegram 容器：50 bit 头、Packet 255 终止、固定长度填充、逻辑载荷与信道帧往返。
- Balise Group：按观测顺序记录正向/反向过顶，按国家码和组号解析 Linking Telegram 的目标，区分匹配、未匹配和歧义。
- Fixture generator：从轨旁场景配置生成稳定的逻辑报文和原始 341/1023 bit 测试向量。
- Validation / schema / diff：提供字段宽度 schema、语义校验报告、Packet 查询、位差异和 Telegram 语义差异工具。
- Trace / track helpers：提供确定性变异向量、LFSR scrambler 接口、正反向过顶报告和轨道速度/制动距离评估。

## 运行示例

需要 MoonBit 0.10.3 或更高版本。当前仓库已在 0.10.7 编译器上验证。

```text
moon check --deny-warn
moon test --deny-warn
moon run cmd/balise-inspect
```

示例命令会打印：

```text
moonbit-balise-telegram
logical payload bits: 830
decoded packet count: 2
```

库的最小使用方式：

```mbt nocheck
let form = long_form()
let header = telegram_header(1, 0, 1, 0, 86, 1200, 0)
let gradient = make_gradient_packet(
  packet_header(packet_gradient_id(), nominal_direction()),
  1,
  [gradient_section(120, true, 8)],
)
let payload = encode_telegram(form, header, [gradient])
let decoded = parse_telegram(payload, form)
```

## 黑客松提案摘要

### 现有基础

这是一个从零开始的 MoonBit 项目。MoonBit 生态中已检索到通用 CRC、网络 packet、Telegram Bot API 和信号处理模块，但没有 Eurobalise、ETCS、CTCS 或铁路应答器报文解析器，因此本项目的领域对象和测试链路不是对成熟 MoonBit 项目的重复包装。

### 新增范围与技术路线

第一阶段建立不依赖外部运行时的位流、码本和 85 bit 校验内核；第二阶段在统一的 `Packet` 枚举上实现 Packet 5/12/21/27；第三阶段用 `BaliseGroup` 和 `Scenario` 组织 Linking Telegram 与正反向过顶；第四阶段补齐示例、错误帧测试、来源记录和 CI。

### 评审可验证项

- `moon run cmd/balise-inspect`：可运行示例。
- `moon test --deny-warn`：29 个测试覆盖位流边界、短/长信道帧、校验破坏、Packet 往返、Telegram 往返、应答器组链接、查询、schema、变异、差异和轨道评估。
- `docs/architecture.md`：模块关系、字段边界和扩展点。
- `docs/protocol-scope.md`：已实现字段与明确未实现内容。
- `.github/workflows/ci.yml`：跨平台格式、信息生成、检查和测试。

## 范围边界

当前版本聚焦“解码后的 bit frame 与逻辑报文”，不包含天线耦合、FSK/相位解调、接收窗口搜索、车载安全平台认证和完整的所有 ETCS Packet。Packet 12/21/27 已提供可运行的核心字段子集；未知包不会被强行解释，而是以 `Packet::Unknown` 保留。后续可加入完整 SUBSET-026 字段表、真实 BTM trace 导入、更多 Packet 和 property-based fuzzing。

## 目录

```text
bitstream.mbt       位流容器、读取器、写入器
codebook.mbt        10→11 信道码本
channel.mbt         341/1023 bit 帧与 85 bit 校验
packets.mbt         Packet 5/12/21/27 与通用包信封
telegram.mbt        Telegram 头、包序列和填充
group.mbt           Balise Group、Linking 和 fixture generator
validation.mbt      语义校验报告
catalog.mbt         Packet catalog、cursor 和 metrics
fuzz.mbt            确定性 fixture 与损坏帧生成
track.mbt           轨道速度与制动距离评估
schema.mbt          Packet 字段 schema
diff.mbt            bit / Telegram 差异报告
scrambler.mbt       可插拔 LFSR scrambler
cmd/balise-inspect  可运行示例
docs/               架构、协议范围、来源与提案说明
```

## 来源与许可证

代码采用 Apache-2.0。协议字段和帧尺寸的依据、第三方材料的许可证说明、码本来源边界见 [docs/sources.md](docs/sources.md)。本仓库没有复制 GPL 示例工程的实现代码；公开参考实现只用于交叉核对字段和多项式常量，所有 MoonBit 实现均在本仓库中独立编写。

`moon.mod` 已使用参赛者的 `RT3452/moonbit-balise-telegram` 模块命名空间，与公开 GitHub 仓库保持一致；Mooncakes 发布仍需参赛者在目标平台确认发布操作。本地仓库已通过 CI 并完成首次推送。
