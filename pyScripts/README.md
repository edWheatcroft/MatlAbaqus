# abYthon
Some basic python modules for interacting with Abaqus. As with the matlab code, there's not much here yet...
None of this code does anything especially complicated, it's purpose is mainly to save me having to refer to the Abaqus manual in order to remember the correct syntax for simple tasks.

The code is structured into a python package called abYthon, which you should be able to install locally with pip.


The general structure of the package is:
- py2/                            Code which only Abaqus' native Python compiler (Python 2.7.15 in Abaqus 2023) can handle safely.
    - logToFile_.py               A function which forces Abaqus to send python shell output (e.g. print()) to a file of the user's choice.
    - loadMat_.py                 A function for loading .mat files using retro python...
    - handlers/                   A module for conducting basic operations with Abaqus objects (run jobs, read output etc.)
           - __init__.py
           - job_.py
           - odb_.py

- py3/                            Code which requires a modern Python compiler (Python 3.X).
    - abYthon/                    A small module for handling the execution of abaqus python scripts. 
           - __init__.py
           - abYthonScript_.py      A class to handle submitting a python script to the ABAQUS Kernel


## Getting Started 

 - Either clone or download the repository
 - Install the abYthon package to YOUR OWN python install using pip.
 - paste the py2 folder into 
 - odbQuery() requires access to abYthon.py2 directly from within ABAQUS python. To set enable this, copy the py2 folder from this repository (pyScripts/abYthon/py2) to your own ABAQUS installation's python lib directory (on Windows, this is somewhere like C:\SIMULIA\EstProducts\20XX\win_b64\tools\SMApy\python2.7\lib\site-packages).

 ## ABAQUS Python Compatibility
 From the 2024 version onwards, ABAQUS  (finally) uses python 3 as its native python interpreter. At present, the above py2 module will not work properly in python 3. This is a problem, as some of the other code in this repo relies on ABAQUS being able to access the py2 library. As a stop gap, I have added py23, which is just py2 converted to valid python 3 syntax. If you are running ABAQUS 2024 or higher, then download the repo as usual, delete py2, rename py23 to 'py2' then follow the instructions above. When I have time, I will add some code to autodetect your ABAQUS version and do this properly.