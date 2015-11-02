########################################################################
# 9/25/12 for a given pdb file this prints out tleap bond commands
# to make cysteine bonds
# it only works with pdb files that have been processed with tleap
# (i.e. in which each atom and residue have a unique number)
# -jpbr
########################################################################
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
######################################################################	
# reference atom variable is "key"
# "dist_dict[key][num][0]" is name of other residue
# "dist_dict[key][num][1]" is distance between key and other residue
######################################################################
#filename = raw_input('enter your pdb filename: ')
 
maxdist=4.0
infile = open(filename)
text = infile.read()
lines_list = text.split('\n')
resnum = [0]*20
resname = {}
x={}
y = [0.0]*20
z = [0.0]*20
index=-1
for line in lines_list:
	if (line[12:16]).find('SG')!=-1:
		index=index+1
		resname[index] = line[17:20].strip() # 3 letter a.a. codes
		resnum[index] = line[22:30].strip() # residue number
		x[index] = float(line[30:38].strip()) # x-coord
		y[index] = float(line[38:46].strip()) # y-coord
		z[index] = float(line[46:54].strip()) # z-coord
for k in range(0,index-1):
	dist=1000
	for j in range(k+1,index):
		temp=dist_btwn_atoms([x[k],y[k],z[k]],[x[j],y[j],z[j]])
		if temp<dist:
			dist=temp
			resnum1=resnum[k]
			resnum2=resnum[j]
	print resnum1 , resnum2 , dist
		
		

#		print str("bond"), str("mol." + all_atoms[key][4] + ".SG"), str("mol." + all_atoms[most_likely_pair][4] + ".SG")

