# MatlAbaqus
A collection of MATLAB and Python scripts for interacting with ABAQUS from MATLAB. 
A lot of this code isn't written especially well/neatly. Tidying it up is an ongoing task...

Currently includes (see individual files for further information):
- mtlbAqs - A MATLAB package containing:
    - readMSG() - A function to extract negative eigenvalue information from ABAQUS' .msg file.
    - readSTA() - A function to extract step and incrementation information from ABAQUS' .STA file.
    - runAbJob() - A function to submit a .inp file from MATLAB.
    - runPyScript() - A function to run an ABAQUS python script from MATLAB
- pyScripts - A directory containing a python package, abYthon, for interacting with ABAQUS' native Python objects.

**This repository is currently under heavy development**

## Getting Started

- Either clone or download the repository.
- Add the repository's folder to the MATLAB path. You can now access the mtlbAqs package in MATLAB using "mtlbAqs.<functionName>"
- Install the abYthon package to YOUR OWN python install using pip.
- If you want to access abYthon.py2 directly from within ABAQUS python, either add its path in the script you are running, or copy the py2 folder to ABQAQUS' lib directory (on Windows, this is somewhere like C:\SIMULIA\EstProducts\2023\win_b64\tools\SMApy\python2.7\lib\site-packages).

### Prerequisites

This product was developed in MATLAB 2024b and earlier.


