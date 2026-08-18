# Protocol scope

## Implemented

- Eurobalise short/long frame sizes: 341 / 1023 bits。
- 10-bit logical symbols to 11-bit channel codewords。
- 85-bit composite check built from the long/short \`f × g\` generator pair。
- Three-bit control region, twelve-bit scrambling region and ten-bit extra-shaping region as explicit fields。
- Packet envelope: \`NID_PACKET\` 8 bit, \`Q_DIR\` 2 bit, \`L_PACKET\` 13 bit。
- Packet 5 Linking core records。
- Packet 12 Movement Authority fixture profile。
- Packet 21 Gradient core records。
- Packet 27 Static Speed core records。

## Deliberately not claimed

- 真实天线/FSK 解调和接收窗口同步。
- 全部 SUBSET-026/036 packet 字段和所有国家/项目扩展。
- 车载 BTM 安全认证、密钥管理和运营规则。
- 物理层扰码器的全部部署参数；当前 API 把扰码区域作为可配置位段，并在逻辑测试中保持可重复。

未知 packet 会被保留为 \`Packet::Unknown\`，以便上层工具进行版本兼容，而不是伪造字段含义。
