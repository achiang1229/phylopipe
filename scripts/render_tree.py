from ete4 import Tree
import sys

treefile = sys.argv[1]
output   = sys.argv[2]

t = Tree(open(treefile).read())

t.render(output)
print(f"Tree rendered to {output}")
