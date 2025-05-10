#plot the background

import sys
import os
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

step_size = int(sys.argv[1])
region = int(sys.argv[2])
num = int(sys.argv[3])
output = sys.argv[4]


dim = int(region/step_size)
matrix = np.zeros((dim,dim))
#
for filename in os.listdir(output):
	file_path = os.path.join(output,filename)
	f = open(file_path,"r")
	lines = f.readlines()
	for line in lines:
		nline = line.strip().split("\t")
		a1 = int(nline[0])
		a2 = int(nline[1])
		a3 = int(nline[2])
		matrix[a1-1,a2-1] += a3
		matrix[a2-1,a1-1] += a3
	f.close()

def replace_with_avg(matrix):
    avg_matrix = np.zeros((dim,dim))
    distance_dict = {}
    for i in range(dim):
        for j in range(dim):
            d = abs(i - j)
            if d not in distance_dict:
                distance_dict[d] = []
            distance_dict[d].append((i, j))
    for d, positions in distance_dict.items():
        values = [matrix[i][j] for (i, j) in positions]
        avg = np.mean(values)
        for (i, j) in positions:
            avg_matrix[i][j] = avg

    return avg_matrix

average_matrix = replace_with_avg(matrix)/num
np.savetxt(str(region)+"_background.txt",average_matrix,fmt='%.3f')

#row_indices, col_indices = np.indices(average_matrix.shape)
#long_matrix = np.column_stack((row_indices.ravel(),col_indices.ravel(),average_matrix.ravel()))
#np.savetxt(str(region)+"_long.txt",long_matrix,fmt='%.3f')

plt.figure(figsize=(8, 8))
sns.heatmap(average_matrix, square=False, cmap='Reds', cbar=False, linewidths=0, linecolor='white', xticklabels=False, yticklabels=False)
plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
plt.savefig(str(region)+"_background.jpg", format='jpg')
