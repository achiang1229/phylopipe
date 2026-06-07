configfile: "config.yaml"

IDS = glob_wildcards("data/{id}.fasta").id

for id in IDS:
    og = (config.get("outgroup") or {}).get(id)
    if og is None or og == "":
        raise SystemExit(
            f"\nERROR: No outgroup specified for '{id}' in config.yaml. "
            f"Please add an entry under 'outgroup'.\n"
        )

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

rule mafft_align:
    input:
        "cleaned/{id}_clean.fasta",
    output:
        "aligned/{id}_aln.fasta"
    params:
        og=lambda wildcards: config["outgroup"][wildcards.id]
    shell:
        """
        python scripts/resolve_outgroup.py {input} "{params.og}" > /dev/null
        mafft --auto --thread -1 {input} > {output}
        """

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
        OG=$(python scripts/resolve_outgroup.py {input.fasta} "{params.og}")
        iqtree3 -s {input.trimmed} --prefix tree/{wildcards.id} -o $OG --redo --alrt 1000 -B 1000 -T AUTO 
        """

rule render_tree:
    input:
        "tree/{id}.treefile"
    output:
        "tree/{id}.png"
    shell:
        "python scripts/render_tree.py {input} {output}"
