#
import sys
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
#from matplotlib.colors import LinearSegmentedColormap

#chr = sys.argv[1]
#start = sys.argv[2]
#end = sys.argv[3]
#window = sys.argv[4]
#step = sys.argv[5]
#interaction_dir = sys.argv[6]
input = sys.argv[1]
out = sys.argv[2] 
dim = int(sys.argv[3])
#background_matrix = np.loadtxt(sys.argv[3])

matrix = np.zeros((dim,dim))

f = open(input,"r")
lines = f.readlines()
for line in lines:
	nline = line.strip().split("\t")
	a1 = int(nline[0])
	a2 = int(nline[1])
	a3 = float(nline[2])
	matrix[a1-1,a2-1] = a3
f.close()

#ormalized_matrix = (matrix+1)/(background_matrix+1)
#upper_matrix = np.triu(normalized_matrix,k=0)
plt.figure(figsize=(8, 8))
sns.heatmap(matrix, square=True, cmap="Reds", cbar=False, linewidths=0, linecolor='white', xticklabels=False, yticklabels=False,)

plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
plt.savefig(out, format='jpg')
