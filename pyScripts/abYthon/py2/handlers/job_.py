'''
A class to manage and run Abaqus jobs using the Abaqus scripting job object.
Can be run with or without the Abaqus kernel.
'''


import os
import shutil
import stat
from abaqusConstants import *

class job:
    outputDirName = 'bin'
    inputDirName = 'source'

    # The class will place files in the following structure:
    # binFolder/source - input files
    # binFolder/bin    - output files


    def __init__(self, jobObject, binFolder='runDir', debug=True):
        self.jobJect = jobObject                                                # an instance of an Abaqus job object
        self.name = jobObject.name                                              # name of the job
        self.binFolder = binFolder                                              # folder to store job files
        self.inpDirPath = os.path.join(self.binFolder, self.inputDirName)       # relative path to input directory
        self.outDirPath = os.path.join(self.binFolder, self.outputDirName)      # relative path to output directory
        self.inpFileName = self.name + '.inp'                                   # name of the input file
        self.odbAbsPath = os.path.abspath(os.path.join(self.outDirPath, self.name + '.odb'))  # absolute path to the odb file
        self.debug = debug                                                      # debug flag


    def run(self, makeBat=True):

        # make the bin folder if it doesn't exist
        self.makeBinFolder()
        
        # write the iput file
        self.writeINP()

        # make a .bat file to run the job if requested
        if makeBat:
            self.writeSubmissionBat()

        # make the output directory if it doesn't exist using vintage python syntax
        if not os.path.exists(self.outDirPath):
            os.makedirs(self.outDirPath)                               

        # note where we are and change to the output directory
        currDir = os.getcwd()
        os.chdir(self.outDirPath)

        # submit the job and wait for completion
        self.jobJect.submit()           # no need to do the consistency check, we've done it already in writeINP
        print("Job submitted. Waiting for completion...")
        self.jobJect.waitForCompletion()
        print("Job completed.")

        # clean up the input file and return to where we were
        os.remove(self.name + '.inp')
        os.chdir(currDir) 



    def writeINP(self):
        '''
        Write the input file to the input directory.
        '''
        # make the input directory if it doesn't exist using vintage python syntax
        if not os.path.exists(self.inpDirPath):
            os.makedirs(self.inpDirPath)                  

        if self.debug:
            consChecking = ON
        else:
            consChecking = OFF
        
        # write the input file, changing back to where we were
        currDir = os.getcwd()
        os.chdir(self.inpDirPath)
        self.jobJect.writeInput(consistencyChecking=consChecking)
        os.chdir(currDir)


    def writeSubmissionBat(self):
        """
        Writes a .bat file to the input directory which can be double clicked to run the model, placing output in the output directory.
        This is just to make life easier when debugging, turn it off when running many jobs.
        """

        inpRelPath = os.path.join('..', self.inputDirName, self.inpFileName)
        batPath = os.path.join(self.inpDirPath, 'submitJob.bat')


        bat_contents = [
            "@echo off",
            "REM Create ../bin directory if it does not exist",
            "if not exist ..\\" + self.outputDirName + " mkdir ..\\" + self.outputDirName,
            "",
            "REM Change to ../bin",
            "pushd ..\\"+ self.outputDirName,
            "",
            "REM Run Abaqus job",
            "abaqus job={} input={} interactive".format(self.name, inpRelPath),
            "",
            "REM Return to original directory",
            "popd",
            "",
            "pause"
        ]

        try:
            with open(batPath, 'w') as f:
                f.write('\r\n'.join(bat_contents))
            print("BAT file written to: {}".format(batPath))
        except IOError as e:
            print("Failed to write BAT file: {}".format(e))


    def makeBinFolder(self):
        '''
        Make the bin folder if it doesn't exist using vintage python syntax.
        Also deletes the existing folder and its contents if it already exists.
        '''

        binAbsPath = os.path.abspath(self.binFolder)

        # delete the existing folder and its contents if it already exists
        if os.path.exists(binAbsPath):
            if self.debug:
                print("Deleting existing bin folder: {}".format(binAbsPath))
            shutil.rmtree(binAbsPath, onerror=self.remove_readonly)
        

        os.makedirs(binAbsPath)


    def remove_readonly(self, func, path, excinfo):
        # func = the function that raised the exception (os.remove, os.rmdir)
        # path = the path it tried to delete
        # excinfo = exception info
        os.chmod(path, stat.S_IWRITE)  # make writable
        func(path)  # retry
