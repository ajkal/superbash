import sys
import os
import math
for arg in sys.argv:
	filename=arg
			
def dist_btwn_atoms((atom1_coords),(atom2_coords)):
	"""computes distance between atoms given their coords (x,y,z)"""
	distx = atom2_coords[0] - atom1_coords[0]
	disty = atom2_coords[1] - atom1_coords[1]
	distz = atom2_coords[2] - atom1_coords[2]
	dist = math.sqrt(distx**2 + disty**2 + distz**2)
	return dist

# RUN PROGRAM
 
maxdist=6.25
infile = open(filename)
text = infile.read()
lines_list = text.split('\n')
resnum = {};resname = {}
x={};y = {};z = {};dist={}
index=-1
sys.stdout.softspace=False
for line in lines_list:
	if (line[12:16]).find('SG')!=-1:
		index=index+1
		resname[index] = line[17:20].strip() # 3 letter a.a. codes
		resnum[index] = line[22:30].strip() # residue number
		x[index] = float(line[30:38].strip()) # x-coord
		y[index] = float(line[38:46].strip()) # y-coord
		z[index] = float(line[46:54].strip()) # z-coord
for k in range(0,index):
	dist[k]=1000.0
	for j in range(k+1,index+1):
		temp=dist_btwn_atoms([x[k],y[k],z[k]],[x[j],y[j],z[j]])
		if temp<dist[k]:
			dist[k]=temp
			resnum1=resnum[k]
			resnum2=resnum[j]
        str1=' '*(5-int(math.trunc(math.log10(float(resnum1)))))
	str2=' '*(5-int(math.trunc(math.log10(float(resnum2)))))
	if dist[k]<maxdist:
		print "sed -i 's/CYS"+str1+str(resnum1)+"/CYX"+str1+str(resnum1)+"/g' $1/build/leap2.pdb "
		print "sed -i 's/CYS"+str2+str(resnum2)+"/CYX"+str2+str(resnum2)+"/g' $1/build/leap2.pdb "


