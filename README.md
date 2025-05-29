# SBT_Analysis_MOH
This pipeline performs sequence-based typing (SBT) of Legionella pneumophila isolates using the el_gato tool.

This WDL workflow runs **ElGato** (Sequence-Based Typing) analysis on either paired-end reads or an assembly using the `staphb/elgato:1.15.2` Docker image.

## 📦 Requirements

- [Cromwell](https://github.com/broadinstitute/cromwell) or any WDL-compatible runner
- Docker or Singularity
- Input files: Either
  - `read1` and `read2` (paired-end reads)
  - or `assembly` (assembled genome)
- The samplename

## 🚀 Usage

Example command:
```bash
cromwell run sbt_analysis.wdl --inputs inputs.json
