# MatlAbaqus
A collection of MATLAB scripts for interacting with ABAQUS. 
A lot of this code isn't written especially well/neatly. Tidying it up is an ongoing task...

Currently includes (see individual files for further information):
- readMSG() - A function to extract negative eigenvalue information from ABAQUS' .msg file.
- readSTA() - A function to extract step and incrementation information from ABAQUS' .STA file.
- runAbJob() - A function to submit a .inp file from MATLAB.
- runPyScript() - A function to run an ABAQUS python script from MATLAB
- pyScripts - A directory containing a python package, abYthon, for interacting with ABAQUS' native python objects.

**This repository is currently under heavy development**

## Getting Started

- Either clone or download the repository.
- Add the repository's folder to the MATLAB path.
- Install the abYthon package to YOUR OWN python install using pip.
- If you want to access abYthon.py2 directly from within ABAQUS python, either add its path in your script, or copy the py2 folder to ABQAQUS' lib directory (somewhere like C:\SIMULIA\EstProducts\2023\win_b64\tools\SMApy\python2.7\lib\site-packages).

### Prerequisites

This product was developed in MATLAB 2024b and earlier.


