Memento Pipeline
Memento is a 1-click pipeline capable of processing raw 16s amplicon data

Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

Prerequisites and installations
What things you need installed:
SRA-toolkit to download fastqs directly from SRA:
conda install -c daler sratoolkit

QIIME2 to process reads and build classifier:
conda install -c qiime2 qiime2

PICRUST2 to predict ECs and metabolic pathways:
conda install -c bioconda picrust2
Or
conda install -c bioconda/label/cf201901 picrust2

Deployment
The pipeline calls each module as and when it is required. 
Built With
	•	Dropwizard - The web framework used
	•	Maven - Dependency Management
	•	ROME - Used to generate RSS Feeds


Versioning
Memento Pipeline1.0
Authors
	•	Felix O’Farrell - Read processing, Classifier construction and predictor integration
	•	Ariane Duverdier - Statistical analysis of PICRUST2 output

See also the list of contributors who participated in this project:
	•	Ruth Richards - Front end construction and flask 
	•	Slaviana Pavlovich - Construction of the Memento database
	