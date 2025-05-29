version 1.0

workflow sbt_analysis {
  meta {
      description: "SBT Legionella pneumophila isolates using the el_gato tool."
      author: "David Maimoun"
      organization: "MOH Jerusalem"
  }

  input {
    String samplename
    File? assembly
    File? read1 
    File? read2
    String docker = "staphb/elgato:1.21.2"
  }

    if (
      (defined(read1) && defined(assembly)) ||
      (defined(read2) && defined(assembly)) ||
      (defined(read1) && defined(read2) && defined(assembly))
    ) {
        call error_inputs {
            input:
                error_message = "ERROR: Provide only either reads('read1' and 'read2'), or 'assembly' (fasta file) but not both."
        }
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
  input {
    File? read1
    File? read2
    File? assembly
    String samplename
    String docker
  }

  command <<<
    el_gato.py -v > VERSION

    if [[ -n "~{read1}" && -n "~{read2}" ]]; then
      el_gato.py --read1 ~{read1} --read2 ~{read2} --out ./out
    elif [[ -n "~{assembly}" ]]; then
      el_gato.py --assembly ~{assembly} --out ./out
    else
      echo "Missing inputs: Either both reads or an assembly file must be provided." >&2
      exit 1
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

task error_inputs {

  input {
    String error_message
  }
    
    command <<<
      echo "~{error_message}" >&2
      exit 1
    >>>

  runtime {
    docker: "debian:bookworm-slim"

  }
}

