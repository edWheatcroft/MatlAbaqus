Some basic python modules for interacting with Abaqus. As with the matlab code, there's not much here yet...
None of this code does anything especially complicated, it's purpose is mainly to save me having to refer to the Abaqus manual in order to remember the correct syntax for simple tasks.

The code is structured into a python package called abYthon, which you should be able to install locally with pip.


The general structure of the package is:
py2/                            Code which only Abaqus' native Python compiler (Python 2.7.15 in Abaqus 2023) can handle safely.
    logToFile_.py               A function which forces Abaqus to send python shell output (e.g. print()) to a file of the user's choice.
    handlers/                   A module for conducting basic operations with Abaqus objects (run jobs, read output etc.)
            __init__.py
            job_.py
            odb_.py

py3/                            Code which requires a modern Python compiler (Python 3.X).
    abYthon/                    A small module for handling the execution of abaqus python scripts. 
            __init__.py
            abYthon_.py
