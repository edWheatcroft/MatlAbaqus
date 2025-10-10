'''
A class to run Abaqus python scripts from within python.
'''

import os
import time
import subprocess
from pathlib import Path

class abYthonScript:
    def __init__(self, scriptName, caeKernel = False, runDir = Path.cwd()):
        
        # ensure script name ends with .py
        if not scriptName.endswith('.py'):
            scriptName = scriptName + '.py'

        
        self.scriptName = scriptName        
        self.caeKernel = caeKernel
        self.runDir = Path(runDir)          # directory of the script. this is also where it will be run from



    def run(self, userArgs = None):

        # build the command string
        cmdString = self.buildCmd(userArgs)

        # run the script
        print(f'Running script {self.scriptName} in directory {self.runDir}')
        start_time = time.time()
        output = subprocess.run(cmdString, shell=True, cwd=self.runDir, capture_output=True, text=True)
        end_time = time.time()
        elapsed_time = end_time - start_time

        print("STDOUT:\n", output.stdout)
        print("STDERR:\n", output.stderr)
        print("Exit code:", output.returncode)
        print("Script completed in %.3f seconds" % elapsed_time)

        time.sleep(2)   # wait a couple of seconds to ensure all files are closed properly before cleaning up
        self.cleanUp()


    def buildCmd(self, userArgs = None):
        if self.caeKernel:
            cmdString = f'abaqus cae noGUI={self.scriptName}'
        else:
            cmdString = f'abaqus python {self.scriptName}'

        if userArgs is not None:
            cmdString += ' -- '  # Abaqus requires a -- before user args
            # do some basic checks on user args
            for arg in userArgs:
                if not isinstance(arg, str):
                    raise ValueError("All user arguments must be strings.")
                
                if ' ' in arg:
                    raise ValueError("User arguments cannot contain spaces. Please split arguments accordingly.")
                
                cmdString += ' "' + arg + '"'

        return cmdString


    def cleanUp(self):
        

        # change to the run directory
        currDir = os.getcwd()
        os.chdir(self.runDir)

        for fname in ['abaqus.rpy', 'abaqus.rec']:
            try:
                os.remove(fname)
                print("Removed:", fname)
            except OSError:
                pass

        # return to where we were
        os.chdir(currDir)


        
