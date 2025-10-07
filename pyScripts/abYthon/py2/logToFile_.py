## a script to force ABAQUS to send python shell command line output to a log file
import os
import sys

def logToFile(logFileName='logFile', logDir=os.getcwd()):
    logname = os.path.join(logDir, logFileName + '.log')
    sys.stdout = open(logname, 'w')
    sys.stderr = sys.stdout
    print('Logging shell output to ' +  logname)

