import scipy.io as sio
from .loadMat_ import loadMat
from .logToFile_ import logToFile
import handlers
import sys
import os


def queryODB(inputPath):
    # set up logging (left here in case you want to debug this in future)
    #scriptName = 'queryODBLogs'
    #logToFile(logFileName=scriptName, logDir=os.getcwd())
    
    # load the input data
    inpData = loadMat(inputPath)

    # get the odb file
    odbCls = handlers.odb(inpData['odbPath'])

    # initialise output
    outputDict = []
    queries = inpData['queries']
    if not isinstance(queries[0], list):    # some code to deal with the single query case
        queries = [queries]
    # loop over the queries
    for query in queries:
        # get information about the query
        stepName = query[0]
        setName = query[1]
        instName = query[2]
        variableName = query[3]
        compVariant = query[4]

        # determine how to query the odb
        if setName == 'globalHistory':
            fOutput = odbCls.HoutputFromRegion(stepName=stepName, region='Assembly ASSEMBLY', variableName=variableName)
        else:
            setAsRegion = odbCls.getRegionFromSet(setName=setName, instanceName=instName)
            if type(compVariant) is str:
                fOutput = odbCls.getMultiFOutput(stepName=stepName, region=setAsRegion, variableName=variableName, invariant=compVariant)
            else:
                fOutput = odbCls.getMultiFOutput(stepName=stepName, region=setAsRegion, variableName=variableName, component=compVariant)

        # append to the output list
        outputDict.append(fOutput)

    # save the output data
    sio.savemat(inpData['outPath'], {inpData['outDataFieldName']: outputDict})
