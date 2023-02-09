#!/usr/bin/env python3

import sys, os, shutil
from numpy import prod
import pickle
import csv
import re
import pandas as pd

# set working directory
# set working directory
abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)

dynamic_nmf_path = "./dynamic-nmf-model/"
sys.path.append(dynamic_nmf_path)

from text.slices import TimeSlices
from text.prepare import create_text_files
from text.prepare import process_text
import unsupervised
from estimate.window import FitWindow
from estimate.window import SelectWindowTopics
from estimate.dynamic import FitDynamic
from estimate.dynamic import SelectDynamicTopics

import random
from datetime import datetime
from operator import itemgetter

#------------------------------------------------------------------
# Read data and initialize data
print('Dynamic Topic Model of Le Figaro newspaper issues \n\n')

# Declare corpus name and create output directory
corpus = 'newspaper'
output_directory = "./output_le_figaro"
if os.path.exists(output_directory):
    shutil.rmtree(output_directory)
os.makedirs(output_directory)

print('Load the sample data.')
df = pd.read_csv("./corpora/processed_newspaper_text.csv",
                 names=["date", "docid", "text_final"],
                 keep_default_na=False)
content = df.to_dict("records")
content.sort(key=itemgetter('date'), reverse=False)

print('Remove documents with no text')
content = [row for row in content if row['text_final'] != ""]
content = [row for row in content if row['text_final'] != 'text_final']

print('Fix bad dates')
for row in content:
    if row['docid'] == 'bpt6k2867831':
        row['date'] = '1904-1-1'

print('Convert date format')
for row in content:
    row['datetime'] = datetime.strptime(row['date'],'%Y-%m-%d')
    row['date'] = row['datetime'].strftime('%d/%m/%Y')

print('Keep observations up to WW1 mobilization')
content = [row for row in content if row['datetime'] < datetime(1914, 8, 4, 0, 0)]

print('Get the "time slice" data needed for the DtmNmfModel class')
ts = TimeSlices(content, 'date')
time_slice_data = ts.get('text_final')

print('Fix time slice -- 5 year intervals')
def FixTimeSlice(data):
    yr1 = 1872
    yr2 = 1876
    while yr2 < 1930:
        if yr1 <= row[-1] <= yr2:
            nyear = str(yr1)+'-'+str(yr2)
            break
        else:
            yr1 += 5
            yr2 += 5
    return (data[0], data[1], nyear)

time_slice_data2 = []
for row in time_slice_data:
    temp = FixTimeSlice(row)
    time_slice_data2.append(temp)

time_slice_data = time_slice_data2

#---------------------------------------------------------------------
print('Prepare data for nmf')
# Create data that dynamicnmf likes
# Create data directory for text files
text_directory = "{}/newspaper_text_data".format(output_directory)
if os.path.exists(text_directory):
    shutil.rmtree(text_directory)
os.makedirs(text_directory)
# Generate time sliced text files
dpaths = create_text_files(time_slice_data, text_directory, overwrite = True)

# Extract paths
paths = [row[-1] for row in dpaths]

print('Process text')
texts = process_text(paths, minlen = 0)

print("Get window topics")
ks = [15,15,15,15,15,15,15,15,15]
fw = FitWindow(texts, ks)
window_topics = fw.fit()

#---------------------------------------------------------------------
print('Generate dynamic topic keywords and document-topic weight matrix')
max_k = 15  # declare max topic
print('Estimating dynamic topic model with k = {}'.format(max_k))
fd = FitDynamic(window_topics)
fd.fit(max_k, verbose = True)
keywords = fd.get_dynamic_topics(20)
document_topic_matrix = fd.get_document_topics()
results = fd.fit_results
#-----------------------------------------------
# write keywords and topic data to disk
print("Saving data to disk...")
#construct labels for dt_matrix
labels = ['nmf_docid']
id = 0
while id <= max_k-1:
    labels.append('topic'+str(id))
    id += 1
#get docids
docids = [row[0] for row in time_slice_data]
#To get the metadata, we will need to ignore entries in the original dataset that were dropped when generating time window data.
filtered_content = [row for row in content if row['docid'] in docids]
#get doc lengths
doc_lengths = [len(row['text_final']) for row in filtered_content]
#create dataframes
df_docids = pd.DataFrame(docids, columns=['docid']) # document ids
df_doc_lengths = pd.DataFrame(doc_lengths, columns=['doc_lengths']) # document lengths
df_dtmatrix = pd.DataFrame(document_topic_matrix, columns=labels) #document-dynamic topic matrix
df_dynamic_topics = pd.concat([df_docids, df_doc_lengths, df_dtmatrix], axis=1)  # merge docids with document-topic matrix
df_data = pd.DataFrame(filtered_content) # filtered content
df_keywords = pd.DataFrame(keywords) # dynamic topic top terms
print('Merge data')
df_merged = pd.concat([df_data, df_dynamic_topics], axis=1)

print("Drop text and save topic model results")
df_merged = df_merged.drop(['text_final', 'datetime', 'date_time'], axis=1)
path = '{}/{}_k{}_dtmatrix_compact.csv'.format(output_directory, corpus, max_k)
df_merged.to_csv(path, encoding='utf-8', index=None)
# save keywords
path = '{}/{}_k{}_keywords.csv'.format(output_directory, corpus, max_k)
df_keywords.to_csv(path, encoding='utf-8', index=None)
# save data
path = '{}/{}_k{}_dtm_results.pkl'.format(output_directory, corpus, max_k)
with open(path, 'wb') as pfile:
    pickle.dump(results, pfile)

print("Delete temporary text files")
shutil.rmtree(text_directory)

print('Dynamic NMF model run completed. \n\n')



