version 1.0

workflow sbt_analysis {
  input {
    String samplename
    File? assembly
    File? read1 
    File? read2
    String docker = "staphb/elgato:1.15.2"
  }

  call validate_inputs {
    input:
      assembly = assembly,
      read1 = read1,
      read2 = read2
  }

  
  call elgato_reads {
    input:
      read1       = read1,
      read2       = read2,
      assembly    = assembly,
      samplename  = samplename,
      docker      = docker
  }

  output {
    String sbt_elgato_version = elgato_reads.elgato_version
    String sbt = elgato_reads.sbt
    File sbt_possible_sts = elgato_reads.possible_mlsts
    File sbt_inter_out = elgato_reads.intermediate_outputs
    File sbt_alleles = elgato_reads.alleles
  }
}


task elgato_reads {
  File? read1
  File? read2
  File? assembly
  String samplename
  String docker

  command <<<
    el_gato.py -v > VERSION

    if [[ -n ~{read1} ]];then
      el_gato.py --read1 ~{read1} --read2 ~{read2} --out ./out
    else
      el_gato.py --assembly ~{assembly} --out ./out
    fi

    st=$(awk -F "\t" 'NR==2 {print $2}' ./out/possible_mlsts.txt)
    if [ -z "$st" ]; then
      st="No ST predicted!"
    else
      st="ST"$st
    fi
    echo $st > SBT

    mv out/possible_mlsts.txt ~{samplename}_possible_mlsts.txt
    mv out/intermediate_outputs.txt ~{samplename}_intermediate_outputs.txt
    mv out/identified_alleles.fna ~{samplename}_identified_alleles.fna
  >>>

  output {    
    String elgato_version = read_string("VERSION")
    String sbt = read_string("SBT")
    File possible_mlsts = "~{samplename}_possible_mlsts.txt"
    File intermediate_outputs = "~{samplename}_intermediate_outputs.txt"
    File alleles = "~{samplename}_identified_alleles.fna"
  }

  runtime {
    docker: docker
    memory: "8G"
    cpu: 2
  }
}

task validate_inputs {
  File? assembly
  File? read1
  File? read2

  command <<<
    if [[ -n "${assembly}" && ( -n "${read1}" || -n "${read2}" ) ]]; then
      echo "ERROR: Provide either assembly or read1/read2, not both." >&2
      exit 1
    fi

    if [[ -n "${read1}" && -z "${read2}" ]] || [[ -z "${read1}" && -n "${read2}" ]]; then
      echo "ERROR: Both read1 and read2 must be provided together." >&2
      exit 1
    fi

    echo "Inputs validated"
  >>>


  runtime {
    docker: "debian:bookworm-slim"

  }
}

