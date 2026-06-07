from Bio import SeqIO
import sys

cleaned_fasta = sys.argv[1]
species_query = sys.argv[2].replace(" ", "_")  # e.g. "Formica_rufa"  # normalize spaces to underscores

matches = []
for record in SeqIO.parse(cleaned_fasta, "fasta"):
    if species_query.lower() in record.id.lower():
        matches.append(record.id)

if len(matches) == 1:
    print(matches[0])
elif len(matches) == 0:
    print(f"ERROR: No match found for '{species_query}'", file=sys.stderr)
    sys.exit(1)
else:
    print(f"ERROR: Multiple matches found for '{species_query}':", file=sys.stderr)
    for m in matches:
        print(f"  {m}", file=sys.stderr)
    print("Please be more specific in your config.", file=sys.stderr)
    sys.exit(1)
