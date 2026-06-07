from Bio import SeqIO
import re
import sys

input_fasta = sys.argv[1]
output_fasta = sys.argv[2]

with open(input_fasta) as infile, open(output_fasta, "w") as outfile:
    for record in SeqIO.parse(infile, "fasta"):
        # NCBI headers: "accession.version description"
        # Extract accession and first two words of description (genus + species)
        parts = record.description.split()
        accession = parts[0]
        # Grab genus and species if present, fall back to accession only
        if len(parts) >= 3:
            species = f"{parts[1]}_{parts[2]}"
            record.id = f"{species}_{accession}"
        else:
            record.id = f"{accession}"
        record.description = ""
        SeqIO.write(record, outfile, "fasta")
