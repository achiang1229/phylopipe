configfile: "config.yaml"

IDS = glob_wildcards("data/{id}.fasta").id

rule all:
    input:
        expand("tree/{id}.png", id=IDS)

rule reformat_headers:
    input:
        "data/{id}.fasta"
    output:
        "cleaned/{id}_clean.fasta"
    shell:
        "python scripts/reformat_headers.py {input} {output}"

rule list_labels:
    input:
        "cleaned/{id}_clean.fasta"
    output:
        "logs/{id}_labels.txt"
    shell:
        "grep '>' {input} | sed 's/>//' > {output}"

rule validate_config:
    input:
        fasta="cleaned/{id}_clean.fasta",
        labels="logs/{id}_labels.txt"
    output:
        touch("logs/{id}_validated.flag")
    run:
        import subprocess, sys
        og = config["outgroup"].get(wildcards.id)
        if og is None:
            raise ValueError(
                f"No outgroup specified for '{wildcards.id}' in config.yaml. "
                f"Please add an entry under 'outgroup'."
            )
        result = subprocess.run(
            ["python", "scripts/resolve_outgroup.py", input.fasta, og],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            raise ValueError(
                f"Config validation failed for '{wildcards.id}':\n{result.stderr}\n"
                f"Check logs/{wildcards.id}_labels.txt for valid outgroup names."
            )

rule mafft_align:
    input:
        fasta="cleaned/{id}_clean.fasta",
        flag="logs/{id}_validated.flag"
    output:
        "aligned/{id}_aln.fasta"
    shell:
        "mafft --auto {input.fasta} > {output}"

rule trimal_trim:
    input:
        "aligned/{id}_aln.fasta"
    output:
        "trimmed/{id}_aln_trim.phy"
    shell:
        "trimal -in {input} -out {output} -phylip"

rule iqtree_infer:
    input:
        fasta="cleaned/{id}_clean.fasta",
        trimmed="trimmed/{id}_aln_trim.phy"
    output:
        "tree/{id}.treefile"
    params:
        og=lambda wildcards: config["outgroup"][wildcards.id]
    shell:
        """
        OG=$(python scripts/resolve_outgroup.py {input.fasta} {params.og})
        iqtree3 -s {input.trimmed} --prefix tree/{wildcards.id} -o $OG --redo
        """

rule render_tree:
    input:
        "tree/{id}.treefile"
    output:
        "tree/{id}.png"
    shell:
        "python scripts/render_tree.py {input} {output}"
