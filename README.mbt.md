# moonbit-balise-telegram

这是 MoonBit 地面应答器报文解析与数据链路仿真器的包文档入口。

核心 API 位于根包：

- `BitReader`、`BitWriter`：MSB-first 位级读写。
- `encode_channel`、`decode_channel`：341/1023 bit 信道帧。
- `encode_packet`、`parse_packet`：Packet 5/12/21/27 和未知包保留。
- `encode_telegram`、`parse_telegram`：逻辑 Telegram。
- `BaliseGroup`、`Scenario`：Linking 和正反向过顶仿真。

完整使用说明、边界和来源见 [README.md](README.md)。
