# MatlAbaqus
A collection of MATLAB and Python scripts for interacting with ABAQUS from MATLAB. 
A lot of this code isn't written especially well/neatly. Tidying it up is an ongoing task...

Currently includes (see individual files for further information):
- mtlbAqs - A MATLAB package containing:
    - readMSG() - A function to extract negative eigenvalue information from ABAQUS' .msg file.
    - readSTA() - A function to extract step and incrementation information from ABAQUS' .STA file.
    - runAbJob() - A function to submit a .inp file from MATLAB.
    - runPyScript() - A function to run an ABAQUS python script from MATLAB.
    - odbQuery() - A class defining a query to an ABAQUS output database (.odb file). Use this to read data from .odb files into MATLAB with zero alteration/pre-processing required at the ABAQUS end. This is a bit slow at the moment, I'll try to speed it up at some stage...
- pyScripts - A directory containing a python package, abYthon, for interacting with ABAQUS' native Python objects.

This codebase is by no means the only, and certainly not the best, option out there for post-processing ABAQUS files. I created these scripts merely to meet my own specific needs over the years. I've put them here in the hope that others also find them useful! 
You may also wish to make use of the excellent web app: Abaqus MSG file analyzer, written by Carl Osterwisch: https://msgfile.info/.
The app plots and tabulates a number of useful outputs from the MSG file. Some of these can be obtained using readSTA(), although Carl's app is much more nicely presented, and also helps locate problem areas of your mesh.

**This repository is currently under heavy development**

## Getting Started

- Either clone or download the repository.
- Add the repository's folder to the MATLAB path. You can now access the mtlbAqs package in MATLAB using "mtlbAqs.functionName"
- Install the abYthon package to YOUR OWN python install using pip.
- odbQuery() requires access to abYthon.py2 directly from within ABAQUS python. To set enable this, copy the py2 folder from this repository (pyScripts/abYthon/py2) to your own ABAQUS installation's python lib directory (on Windows, this is somewhere like C:\SIMULIA\EstProducts\20XX\win_b64\tools\SMApy\python2.7\lib\site-packages). If using ABAQUS 2024 or later, see the note on compatibility in pyScripts/README.md

### Prerequisites

This repository was developed in ABAQUS 2023, and MATLAB 2024b and earlier.


