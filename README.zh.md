# OpenAlex 数据关系型解析器

本项目将 OpenAlex 快照（JSON Lines）转换为符合 CWTS OpenAlex 关系型模式的 CSV 导入文件。除了 `citation` 和 `work_detail` 这两个需要在数据库内后处理生成的表以外，模式中的每一张表都会被直接导出。当前 CWTS 模式包含 88 张表；一旦 CWTS 更新模式，解析器会自动跟随变更。

> OpenAlex 关系型模式由莱顿大学 CWTS 的 Nees Jan van Eck 博士及其团队设计。本项目仅实现解析器代码，原始模式及参考实现请见 https://github.com/CWTSLeiden/CWTS-OpenAlex-databases 。

## 仓库结构

```
openalex-relational-parser/
|-- data/
|   |-- openalex-snapshot-YYYYMMDD/      # OpenAlex JSON 快照（gzip 文件）
|   `-- reference/
|       `-- openalex_cwts_schema.sql     # CWTS 模式（方便起见的本地副本）
|-- output/                              # CLI 运行后生成的 CSV 与 ID 目录
|   `-- reference_ids/                   # CLI 生成的枚举及命名空间 ID
`-- src/
    `-- openalex_parser/
        |-- cli.py                       # 命令行入口
        |-- transformers/                # 各实体 JSON -> CSV 转换器
        `-- ...                          # 辅助模块、模式解析、写入工具等
```

## 安装

- Python 3.9 及以上版本即可，全部逻辑依赖标准库。
- 可选安装 `orjson` 以加速 JSON 解析；若未安装，则自动回落到标准库 `json`。

在运行 CLI 前，请确保 `src` 已加入 `PYTHONPATH`（Windows 使用 `set PYTHONPATH=src`，bash/zsh 使用 `export PYTHONPATH=src`）。

## 工作流程

1. CLI 读取 CWTS 模式 SQL（默认 `data/reference/openalex_cwts_schema.sql`，可用 `--schema` 覆盖）。
2. **collect 阶段**：遍历所选实体，收集所有枚举值（工作类型、许可证、OA 状态等）与辅助命名空间（关键字、原始机构字符串等），并在 `--reference-dir`（默认 `output/reference_ids`）下生成确定性的 ID CSV。重复运行时保留该目录即可跳过收集阶段。
3. **parse 阶段**：再次读取实体，调用转换器生成行数据、去重维度表、并写入 `--output-dir` 中的 CSV。
4. 若指定 `--skip-merged-ids`，CLI 会读取快照附带的 `merged_ids` 目录并跳过所有已合并的 ID。

所有 CSV 均使用模式列顺序、`\t` 作为默认分隔符、UTF-8 编码和 Unix 换行。每个实体都会定期输出 `ProgressReporter` 的进度信息。`citation` 与 `work_detail` 表需在数据落库后通过 SQL 派生生成。

## 使用方法

在仓库根目录执行：

```
set PYTHONPATH=src
python -m openalex_parser.cli --entity all --output-dir output
```

该命令会：

1. 读取 `--schema` 指定的 CWTS 模式。
2. 在 `--reference-dir` 下收集或复用枚举/命名空间 ID。
3. 遍历 `--snapshot`（默认 `data/openalex-snapshot-20250930/data`）中的各实体数据。
4. 为每张模式表输出一个 CSV（不含 `citation` 与 `work_detail`）。
5. 打印各实体的处理进度与汇总。

### CLI 参数

- `--schema PATH`：CWTS 模式 SQL 路径。
- `--reference-dir PATH`：保存枚举与命名空间 CSV 的目录（默认 `output/reference_ids`）。
- `--snapshot PATH`：OpenAlex 快照根目录。
- `--output-dir PATH`：CSV 输出目录（默认 `output`）。
- `--entity NAME`：需要处理的实体，可多次指定；`all` 表示全量。
- `--updated-date YYYY-MM-DD`：仅处理特定 `updated_date=` 分区，可重复。
- `--max-records N`：限制单实体的记录数（`<=0` 表示不限制）。
- `--max-files N`：限制单实体的 gzip 分片数量。
- `--encoding {utf-8,utf-16le}`：输出文件编码（默认 `utf-8`）。
- `--delimiter CHAR`：单字符分隔符（默认 `\t`，支持 `\t`、`,` 等）。
- `--progress-interval N`：进度输出间隔（默认 `1000` 条）。
- `--skip-merged-ids`：忽略快照 `merged_ids/` 目录中列出的已合并 ID。

#### 示例

只处理 `works` 的冒烟测试：

```
python -m openalex_parser.cli ^
    --entity works ^
    --updated-date 2023-05-17 ^
    --max-records 500 ^
    --max-files 2 ^
    --output-dir staging-output
```

只处理 authors 和 institutions，并跳过 merged IDs：

```
python -m openalex_parser.cli --entity authors --entity institutions --skip-merged-ids
```

## 输出内容

- 每张模式表对应一个 CSV（例如 `work.csv`、`institution_relation.csv`、`raw_affiliation_string.csv`）。`citation` 与 `work_detail` 不会直接导出，而是需要在数据库中通过 SQL 基于已导入的 `work_reference` 等表生成。
- `output/reference_ids/`（或指定的 `--reference-dir`）包含生成的枚举 CSV（`license.csv`、`work_type.csv` 等）及命名空间文件（`keyword_ids.csv`、`raw_author_name_ids.csv` 等），取代了旧的 `data/reference/openalex_cwts_sample_export` 数据。
- 国家、关键字、SDG、MeSH、原始作者名、原始机构字符串等共享维度表会使用确定性键去重，确保多实体之间不会重复。

## 字段说明与后处理

- 需要跨行聚合的分析字段（如引用窗口、自引标记等）默认留空，方便在后续分析步骤中填充。
- JSON 解析优先使用 `orjson`，若不可用则回落到标准库 `json`。
- 只要保留 `reference_dir` 内容，解析器将复用既有的枚举与命名空间 ID，保证跨版本运行的稳定性。
- `citation` 表通常通过 `work_reference` 展开并补充引用窗口、自引等派生字段；`work_detail` 用于构建易读的文献引用文本（包含 `author_et_al` 等），推荐在数据库内通过 SQL 生成。

## 故障排查

- **缺少实体目录**：确认 `data/openalex-snapshot-YYYYMMDD/data` 下存在 `works/`、`authors/` 等文件夹；CLI 会自动跳过缺失的实体。
- **冒烟测试过慢**：利用 `--max-records`、`--max-files`、`--updated-date` 控制输入规模。
- **merged IDs 仍被导入**：请确保提供了 `--skip-merged-ids` 并且 `merged_ids/` 目录位于快照路径或其父目录。
- **导入工具需要特定编码/分隔符**：使用 `--encoding` 或 `--delimiter` 覆盖默认设置（例如 SQL Server BULK INSERT 常用 UTF-16LE + 制表符）。

## 下一步建议

- 在数据库内编写 SQL 视图或作业，生成 `citation`、`work_detail` 以及其他分析字段。
- 构建自动化校验流程，将生成的 CSV 头部与 CWTS 模式比对，以便及时发现模式更新。

祝解析顺利！
