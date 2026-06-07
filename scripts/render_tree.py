from ete4 import Tree
from ete4.treeview import TreeStyle, TextFace
import sys

treefile = sys.argv[1]
output   = sys.argv[2]

t = Tree(open(treefile).read(), parser=1)

ts = TreeStyle()
ts.show_leaf_name = True
ts.show_branch_support = False

for node in t.traverse():
    if not node.is_leaf and not node.is_root:
        if node.name and node.name != "Root":
            support_face = TextFace(node.name, fsize=7)
            node.add_face(support_face, column=0, position="branch-top")

t.render(output, tree_style=ts)
print(f"Tree rendered to {output}")
