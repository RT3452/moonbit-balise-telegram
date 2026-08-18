# 2026 MoonBit 8 月黑客松提案

## 项目

`moonbit-balise-telegram`：面向 Eurobalise 与 CTCS 地面应答器 Telegram 报文的信道解码、位级提取、逻辑包解析和 Balise Group 链接仿真库。

## 问题与价值

车载 BTM、信号仿真和协议教学都需要稳定的位级 fixture。现有 MoonBit 模块检索未发现 Eurobalise/ETCS/CTCS 专用实现；通用 CRC 或网络 packet 库不能表达 Packet 12/21/27 的语义，也不能推演应答器组正反向过顶。

## 技术路线

以无外部运行时的 `BitReader` 为底座，实现短/长 Telegram 信道结构、10→11 码本和 85-bit check；在包信封上实现 Linking、Movement Authority、Gradient、Static Speed；用 `Scenario` 生成固定测试向量，用 `BaliseGroup` 将 linking 目标解析为 Matched/Unmatched/Ambiguous 报告；通过 CLI、测试和 CI 保证可复现。

## 交付物

- 可复用根包和可运行 `cmd/balise-inspect`。
- 短/长帧、破坏校验、Packet、Telegram、Group linking 测试。
- README、架构、协议边界、来源与许可证说明。
- CI：格式、接口信息、严格检查和测试。

## 后续扩展

加入完整 packet 字段、BTM trace 导入、更多 Balise Group 规则、property-based fuzzing、Mooncakes 发布和面向其他仿真器的 JSON/CSV 适配器。
