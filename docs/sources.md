# Sources and attribution

本项目只引用公开标准、字段资料和独立验证材料，不复制第三方实现代码。

## Protocol references

- [ERA/UNISIG SUBSET-036 references on EUR-Lex](https://eur-lex.europa.eu/eli/reg_impl/2026/693/oj)：Eurobalise FFFIS/air-gap 规范入口，帧尺寸、码元和校验字段以正式规范为准。
- [openETCS dataDictionary](https://github.com/openETCS/dataDictionary)：用于交叉核对 Packet 5、12、21、27 的字段名称和重复段结构；本仓库没有复制其生成代码。
- [openETCS toolchain](https://github.com/openETCS/toolchain)：用于确认 ETCS 数据字典的包字段组织方式。

## Independent verification

- [SergeyStaroletov/PromelaSamples/Eurobalise.pml](https://github.com/SergeyStaroletov/PromelaSamples/blob/master/Eurobalise.pml)：GPL-licensed Promela model。它被用于独立核对公开的 10→11 码本和 \`f × g\` 多项式常量；本仓库没有复制该 GPL 源码、函数、变量命名或模型结构。若未来采用该仓库的任何代码，必须另行遵守 GPL 并隔离适用范围。

## MoonBit ecosystem search

截至 2026-08-18，通过 [Mooncakes 模块索引](https://mooncakes.io/api/v0/modules) 棢索了 \`balise\`、\`eurobalise\`、\`etcs\`、\`ctcs\`、\`railway\`、\`telegram\`、\`bitstream\`、\`crc\`、\`bch\`、\`packet\` 等关键词。未发现 Eurobalise/ETCS/CTCS/铁路应答器领域的成熟重复项目；命中的 generic CRC、network packet、Telegram Bot 和 diagram/railway-layout 项目不提供本项目的领域功能。

## License

本仓库源代码采用 Apache-2.0，详见根目录 \`LICENSE\`。协议规范本身不随本仓库重新发布；用户应按自己的产品用途取得并遵守适用标准文本和铁路安全法规。
