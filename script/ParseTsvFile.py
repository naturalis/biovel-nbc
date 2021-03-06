import sys,os

sys.stdout.write('Insert the input file location\n') # Metadata TSV file location. the first column is often TaxonID
Input=raw_input()

sys.stdout.write('Insert a list of column names seperated by semicolon\n') # list of headers names that you wish to extract and put them in csv file (e.g. 'GeographicalOrigin;Pathogenic_Potential;Biomass;host;phenology' OR 'Biomass')

Cols=raw_input()

def dict2TSV(D_TaxRequestedValues):
	'''A dictionary having as keys TaxonIDs and as values 
	a list of the values of the requested columns'''
	L=[]
	for TaxID in D_TaxRequestedValues:
		S_KeyValue=TaxID+','+','.join(D_TaxRequestedValues[TaxID])
		L.append(S_KeyValue)
	return L 

def getColsOfInterest(f_in, colNames):
	'''f_in is an input tsv file with headers
	colNames should be a semicolon separated string of headerNames.
	This function outputs a file compatible with ITOL display tools for single
	and multiple value bar charts, where the first line starts with the word 'LABELS'
	and the rest of the file is a comma-separated values.'''
	ColOfInterest={}
	f=open(f_in, 'r')
	Headers=[]
	Headers_temp=f.readline().split('\t')
	for i in Headers_temp:
		Headers.append(i.strip())
	TaxID=Headers[0]
	requestedCols=[]
	for headerName in colNames.split(';'):
		requestedCols.append(Headers.index(headerName))
	requestedCols.sort()
	#print requestedCols
	tempDict_Allfile={}
	for line in f:
		l=line.split('\t')
		tempDict_Allfile[l[0]]=l
	#print tempDict_Allfile
	for Taxon in tempDict_Allfile:
		AllCols=tempDict_Allfile[Taxon]
		for j in requestedCols:
			AllCols[j]=AllCols[j].strip()
			if ',' in AllCols[j]:
				AllCols[j]=AllCols[j].replace(',',';')
				sys.stdout.write('the comma has been replaced by ; in ' + AllCols[j]+ '\n')
				ColOfInterest.setdefault(Taxon,[]).append(AllCols[j])
			else:
				ColOfInterest.setdefault(Taxon,[]).append(AllCols[j])
	f.close()
	f_out=open(f_in + '_ColsOfInterest.csv','w')
	f_out.write('LABELS,'+ ','.join(colNames.split(';')) + '\n')
	Cols2Write=dict2TSV(ColOfInterest)
	f_out.write('\n'.join(Cols2Write)+ '\n')
	f_out.close()

getColsOfInterest(Input, Cols)

