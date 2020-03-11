import pandas as pd
from itertools import repeat
import sys

SRA_acc = sys.argv[1]
path = sys.argv[2]
suffix1 = sys.argv[3]
suffix2 = sys.argv[3]
file_loc = sys.argv[4]
#create df
df = pd.read_csv
df = pd.DataFrame(columns=['sample-id', 'absolute-filepath', 'direction'])
l = []
ll = []  
#open SRA acc sample_ids to df   
with open(SRA_acc) as in_file:  
        line = in_file.readlines()
        c = len(line)
        for i in line:
            l.append((i.strip()))
        ll = [x for item in l for x in repeat(item, 2)]
        ll.sort()      
df['sample-id'] = pd.Series(ll)
#create absoulte filepath from sra acc
#path_ADD = '$PWD/study_title/'
#suffix_ADD1 = '.fastq_1.gz'
#suffix_ADD2 = '.fastq_2.gz'

res = [x + (suffix1 if i%2 == 0 else '') for i, x in enumerate(ll)]
res = [x + (suffix2 if i%2 != 0 else '') for i, x in enumerate(res)]


#filepath = [path_ADD+i+suffix_ADD for i in res]
#add filepath to df
df['absolute-filepath'] = pd.Series(res)   
#add forwards and reverses to final collumn 
list1 = ['forward' for i in range(c)]
list2 = ['reverse' for i in range(c)]
result = [None]*(len(list1)+len(list2))
result[::2] = list1
result[1::2] = list2

df['direction'] = result   
#create manifest csv  
df.to_csv(file_loc, header='sample-id,absolute-filepath,direction', index=None, sep =',')