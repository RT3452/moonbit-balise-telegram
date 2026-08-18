# 2026 MoonBit 8 月黑客松项目申报书

## 一、项目基本信息

- **项目名称**：moonbit 地面应答器（Balise）报文解析与数据链路仿真器
- **项目标识**：`moonbit-balise-telegram`
- **项目类型**：原创协议库与测试工具
- **仓库地址**：<https://github.com/RT3452/moonbit-balise-telegram>
- **许可证**：Apache-2.0

## 二、背景与实际价值

Eurobalise 是 ETCS/CTCS 地面应答器向车载 BTM 传递线路信息的重要接口。实际开发中，解码器、信号仿真器和协议教学都需要可重复的 Telegram 测试向量，但位级信道成形、Packet 语义和 Balise Group 顺序通常分散在专用工具中，难以在 MoonBit 生态中复用。本项目以 MoonBit 为主要实现语言，提供从逻辑报文到 341/1023 bit 信道帧，再反向校验和解析的完整、可测试链路，服务于车载解码模块测试、线路场景仿真和协议学习。

## 三、目标与核心功能

项目目标是建立一个不依赖外部运行时、可扩展的 Eurobalise/CTCS 报文处理内核。当前交付内容包括：

1. MSB-first `BitReader`/`BitWriter`，支持定宽整数、切片、边界错误和字节/十六进制辅助操作。
2. 短报文 341 bit、长报文 1023 bit 信道结构，公开 10→11 码本与 85 bit Block Check 校验。
3. 统一 Packet 枚举和字段 schema，支持 Packet 5 Linking、Packet 12 Movement Authority、Packet 21 Gradient、Packet 27 Static Speed，并保留未知包。
4. Telegram 头、包序列、固定长度填充、逻辑载荷与原始帧的双向编解码。
5. `BaliseGroup` 正向/反向过顶顺序、Linking 目标的 Matched/Unmatched/Ambiguous 判定，以及可重复的场景 fixture 生成。
6. 语义校验、位级/Telegram 差异、确定性损坏向量、LFSR scrambler 接口和轨道速度/制动距离评估。

## 四、实施路线与边界

实施路线为“位流基础设施—信道帧—Packet 语义—Telegram 容器—应答器组—验证工具”。项目聚焦已经解码的 bit frame 和逻辑报文，不虚构射频接收能力；天线耦合、FSK/相位解调、接收窗口搜索、车载安全认证及完整 SUBSET-026 字段表列为后续扩展。后续可增加真实 BTM trace 导入、更多 ETCS Packet、JSON/CSV 适配器和 property-based fuzzing，保持核心 API 稳定。

## 五、验收方式与预期成果

仓库提供可运行示例 `moon run cmd/balise-inspect`、完整 README、架构说明、协议范围、来源与许可证说明，以及 Ubuntu/macOS/Windows CI。当前包含 34 个 MoonBit 源文件、4068 行非空源码和 32 个测试；默认/native 测试全部通过，并对全目标执行严格编译检查。验收重点为短/长帧往返、校验破坏拒绝、Packet 字段边界、Linking 解析、正反向过顶、schema 查询和差异报告。

## 六、开源合规与生态贡献

项目代码采用 Apache-2.0；协议字段依据公开标准和 openETCS 数据资料交叉核对，10→11 码本及校验常量另以公开 Promela 模型独立验证，未复制其实现代码。已在 Mooncakes 模块索引检索 `balise`、`eurobalise`、`etcs`、`ctcs`、`railway`、`telegram`、`bitstream`、`crc`、`bch`、`packet` 等关键词，未发现功能高度重合的成熟 MoonBit 项目。项目将持续维护测试、来源记录、提交历史和发布文档，作为铁路协议工具进入 MoonBit 生态的可复用基础。

**官方活动说明**：<https://bxup9uklfcb.feishu.cn/wiki/KNrVwEVFziPHiGkQtwhc6w3gndd>
