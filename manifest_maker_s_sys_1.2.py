import pandas as pd
import sys
SRA_acc = sys.argv[1]
path = sys.argv[2]
suffix = sys.argv[3]
file_loc = sys.argv[4]

#create df
df = pd.read_csv
df = pd.DataFrame(columns=['sample-id', 'absolute-filepath', 'direction'])
l = []
#open SRA acc sample_ids to df
with open(SRA_acc) as in_file:  
        line = in_file.readlines()
        c = len(line)
        for i in line:
            l.append((i.strip()))
        l.sort()      
df['sample-id'] = pd.Series(l)
#create absoulte filepath from sra acc and path for where fastqs dumped
filepath = [path+i+suffix for i in l]
#add filepath to df
df['absolute-filepath'] = pd.Series(filepath)    
list1 = ['forward' for i in range(c)]
#add forwards to final collumn
df['direction'] = list1 
#create manifest csv  
df.to_csv(file_loc, header='sample-id,absolute-filepath,direction', index=None, sep =',')

