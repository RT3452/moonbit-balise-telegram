# Architecture

\`\`\`text
BitVector / BitReader / BitWriter
              │
              ├── channel.mbt
              │     ├── 10→11 codebook
              │     └── 85-bit block check
              │
              ├── packets.mbt
              │     ├── common packet envelope
              │     ├── Packet 5 / 12 / 21 / 27
              │     └── Packet::Unknown
              │
              ├── telegram.mbt
              │     ├── fixed header
              │     ├── packet sequence
              │     └── Packet 255 + padding
              │
              └── group.mbt
                    ├── BaliseGroup observations
                    ├── forward / reverse order
                    └── Linking resolution reports
\`\`\`

## 关键不变量

1. 所有位流操作都显式携带宽度；越界不会被静默补零。
2. \`encode_channel\` 只接受 210/830 bit 逻辑数据，最终帧严格为 341/1023 bit。
3. Block Check 计算覆盖控制、扰码种子、额外成形位和 10→11 成形数据；校验失败时 \`decode_channel\` 返回 \`CheckFailed\`。
4. Packet 长度由编码器计算，解析器以 \`L_PACKET\` 截取包体；未知 packet 保留原始 body。
5. Group linking 按 \`(NID_C, NID_BG)\` 匹配，不把“没有匹配”误判为成功。

## 扩展点

- 为 \`Packet\` 增加新的 packet family，不改动信道层。
- 为 \`ChannelFrame\` 增加可插拔 scrambler，不改变包解析 API。
- 将 \`Scenario\` 替换为 trace reader，即可复用 group resolver 做真实记录回放。
