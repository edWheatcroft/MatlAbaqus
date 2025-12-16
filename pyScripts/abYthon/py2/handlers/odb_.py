"""
A class to handle operations on Abaqus output databases (.odb files).
Can be used with or without the CAE kernel.
"""

from odbAccess import openOdb
from abaqusConstants import *
import numpy as np

class odb:


    def __init__(self, odbPath):
        """
        Initializes the odb class with the path to the .odb file.

        Parameters:
        -----------
        odbPath : str
            Path to the output database (.odb file).
        """
        odb_ = openOdb(odbPath)
        if odb_ is None:
            raise FileNotFoundError("Could not open ODB file at {}. Please check the path and try again.".format(odbPath))
        

        self.odb = odb_
        self.odbPath = odbPath
        

    @staticmethod
    def exists(odbPath):
        """
        Checks if the specified .odb file exists and can be opened.

        Parameters:
        -----------
        odbPath : str
            Path to the output database (.odb file).

        Returns:
        --------
        bool
            True if the .odb file exists and can be opened, False otherwise.
        """
        try:
            odb_ = openOdb(odbPath)
            if odb_ is not None:
                odb_.close()
                return True
            else:
                return False
        except Exception as e:
            return False


    def isStep(self, stepName):
        """
        Checks if the specified step exists in the ODB file.

        Parameters:
        -----------
        stepName : str
            Name of the analysis step to check.

        Returns:
        --------
        bool
            True if the step exists, False otherwise.
        """
        odb_ = self.odb
        hasStep = odb_.steps.has_key(stepName)
        return hasStep
    

    def stepHasFrames(self, stepName):
        """
        Checks if the specified step contains any frames.

        Parameters:
        -----------
        stepName : str
            Name of the analysis step to check.

        Returns:
        --------
        bool
            True if the step contains frames, False otherwise.
        int
            Number of frames in the step.
        """
        odb_ = self.odb
        if not self.isStep(stepName):
            raise ValueError("Step '{}' not found in the output database.".format(stepName))
        
        numFrames = len(odb_.steps[stepName].frames)
        hasFrames = numFrames > 0

        return hasFrames, numFrames


    def close(self):
        """
        Closes the ODB file.
        """
        if self.odb is not None:
            self.odb.close()
            self.odb = None
        else:
            raise RuntimeError("ODB file is already closed or was never opened.")
        


    def getSingleFOutput(self, stepName, nodeSetName, variableName, component):
        '''
        Extracts field output data for a specific variable and component at a single node set from a given step in an Abaqus ODB file.
        Parameters
        ----------
        stepName : str
            The name of the analysis step from which to extract data.
        nodeSetName : str
            The name of the node set from which to extract data. Must be a valid node set at the assembly level.
        variableName : str
            The name of the field output variable to extract (e.g., 'U' for displacement, 'S' for stress).
        component : int (1, 2, or 3)
            The component of the variable to extract (1 for X, 2 for Y, 3 for Z).
        
        Returns
        ------- -------
        dict
            A dictionary containing:
                - 'time': numpy.ndarray
                    Array of time or frame values corresponding to the extracted data.
                - 'data': numpy.ndarray
                    Array of the extracted variable data for the specified component.
                - 'set': str
                    The name of the node set from which data was extracted.
                - 'variable': str
                    The name of the variable and component extracted (e.g., 'U1' for X displacement).
        
        Raises
        ------
        ValueError
            If the specified step or node set does not exist in the ODB file.
        '''

        odb_ = self.odb
        step = odb_.steps[stepName]

        try:
            node_set = odb_.rootAssembly.nodeSets[nodeSetName.upper()]
        except KeyError:
            odb_.close()
            raise ValueError("Set '{}' not found in the output database.".format(nodeSetName))

        timeSeries = []
        dataSeries = []

        for frame in step.frames:
            time = frame.frameValue
            timeSeries.append(time)


            dataField = frame.fieldOutputs[variableName]
            subset = dataField.getSubset(region=node_set)
            nodeData = subset.values[0]                     # Gives us a FieldValue obect. Index is zero because we assume single node in the set
            data = nodeData.data[component-1]               # .data is a tuple of the vector components. nodeData also has a load of other handy fields, e.g the invariants etc.
            dataSeries.append(data)

        output = {
            'time': np.array(timeSeries),                     # I've keyed this as 'time', but really it's arc length if this is a Riks step
            'data': np.array(dataSeries),
            'set': nodeSetName,
            'variable': variableName + str(component),
        }

        
        return output
    


    def getMultiFOutput(self, stepName, variableName, frames = None, component = None, invariant = None, region = None):
        """
        Extracts field output data for a specific variable from a given step in an Abaqus ODB file.
        Can extract either a specific component of a vector/tensor variable or an invariant.
        Each row of output['data'] corresponds to an analysis frame.

        Make sure that the region and frame range you query all contain the same number of values.
        
        Parameters
        ----------
        stepName : str
            The name of the analysis step from which to extract data.
            The function does not pre-check if the step exists, so if it doesn't, Abaqus will throw an error.
        variableName : str
            The name of the field output variable to extract (e.g., 'U' for displacement, 'S' for stress).
        frames : list of int, optional
            List of frame indices to extract. If None, all frames in the step are extracted. Default is None.
            No pre-check is done to ensure the frames exist, so if an invalid frame index is provided, Abaqus will throw an error.
        component : int, optional
            The component of the variable to extract (1 for X, 2 for Y, 3 for Z, etc.).
            Mutually exclusive with 'invariant'. Default is None.
        invariant : str, optional
            The invariant of the variable to extract (e.g., 'mises' for von Mises stress).
            Mutually exclusive with 'component'. Default is None.
        region : odb.Region, optional
            An Abaqus odb.Region object to subset the field output (e.g., a node set or element set).
            If None, the entire field output is used. Default is None.
        
        Returns
        -------
        dict
            A dictionary containing:
                - 'time': numpy.ndarray 
                    Array of time or frame values corresponding to the extracted data.
                - 'data': numpy.ndarray
                    2D array of the extracted variable data, with shape (numFrames, numValues).
                - 'variable': str
                    The name of the variable extracted.
                - 'component' or 'invariant': int or str
                    The component number or invariant name extracted.
        
        Raises
        ------
        ValueError
            If both 'component' and 'invariant' are specified, or if neither is specified.
            
        """
            

        # validate arguments
        if component is not None and invariant is not None:
            raise ValueError("Cannot specify a component AND an invariant")
        if component is None and invariant is None:
            raise ValueError("Must specify either a component or an invariant")
        # ... and set up something handy for the output dict
        if component is not None:
            compVariant = str(component)
        else:
            compVariant = invariant
    

        # work out which frames to extract
        if frames is None:
            _, numFrames = self.stepHasFrames(stepName)
            frameIDs = range(numFrames)        # default to all frames
        else:
            frameIDs = frames                     # user specified frames
            numFrames = len(frameIDs)


        # set some stuff up for the loops
        if region is None:
            sampleFrameValues = self.odb.steps[stepName].frames[frameIDs[0]].fieldOutputs[variableName].values
        else:
            sampleFrameValues = self.odb.steps[stepName].frames[frameIDs[0]].fieldOutputs[variableName].getSubset(region=region).values
        sampleFrameValue = sampleFrameValues[0]
        if sampleFrameValue.sectionPoint is None:
            spFlag = False
        else:
            spFlag = True
        
        numVals = len(sampleFrameValues)
        valIDs = range(numVals)                     # compute here once to speed up the loop
        time = np.zeros(numFrames)                  # preallocate time array
        time[:] = np.nan                            # set to nan so we can see if we miss any
        out = np.zeros((numFrames, numVals))        # preallocate output array
        out[:,:] = np.nan

        # preallocate arrays to hold location about the values
        nodeIDs = np.zeros(numVals)
        nodeIDs[:] = np.nan
        elIDs = np.zeros(numVals)
        elIDs[:] = np.nan
        intPts = np.zeros(numVals)
        intPts[:] = np.nan
        faceIDs = np.zeros(numVals)
        faceIDs[:] = np.nan
        sectionPoints = np.zeros(numVals)
        sectionPoints[:] = np.nan
        positions = []
        # populate the location arrays from the sample frame
        for valID in valIDs:
            valObj = sampleFrameValues[valID]
            nodeIDs[valID] = valObj.nodeLabel
            elIDs[valID] = valObj.elementLabel
            intPts[valID] = valObj.integrationPoint
            faceIDs[valID] = valObj.face
            if spFlag:
                # the section point object also comes with another attribute - 'description'. You might want to add this in here later.
                sectionPoints[valID] = valObj.sectionPoint.number
            if valObj.position == NODAL:
                positions.append('NODAL')
            elif valObj.position == INTEGRATION_POINT:
                positions.append('INTEGRATION_POINT')
            elif valObj.position == ELEMENT_NODAL:
                positions.append('ELEMENT_NODAL')
            elif valObj.position == ELEMENT_FACE:
                positions.append('ELEMENT_FACE')
            elif valObj.position == CENTROID:
                positions.append('CENTROID')

        # you can't slice abaqus frame/value objects, so unfortunately we have to loop through them, which is slow
        # loop over the frames...
        for frameID in frameIDs:
            # access the frame object and get the time
            frameObj  = self.odb.steps[stepName].frames[frameID]
            time[frameID] = frameObj.frameValue

            # get the field output object, doing any subsetting if required
            if region is None:
                fOutObj = frameObj.fieldOutputs[variableName]
            else:
                # at some stage we might want to add the ability to specify a node set or element set here, probably by subcontracting the sub-setting job to another function
                fOutObj = frameObj.fieldOutputs[variableName].getSubset(region=region)
            
            # ...and then loop over the values in that frame
            for valID in valIDs:
                valObj = fOutObj.values[valID]
                if component is not None:
                    out[frameID, valID] = valObj.data[component-1]      # .data is a numpy array
                else:
                    try:
                        out[frameID, valID] = getattr(valObj, invariant)    # e.g. valObj.mises
                    except AttributeError:
                        raise ValueError("Invariant '{}' not found for variable '{}'. Make sure you've formatted the name in camelCase.".format(invariant, variableName))
        
        
        output = {
            'time': time,               # I've keyed this as 'time', but really it's arc length if this is a Riks step
            'data': out,
            'variable': variableName,
            'compVariant': compVariant,
            'dataName': variableName + compVariant,
            'positions': positions,
            'nodeIDs': nodeIDs,
            'elIDs': elIDs,
            'integrationPoints': intPts,
            'faceIDs': faceIDs,
            'sectionPoints': sectionPoints
        }

        return output


            

    def HoutputFromRgn(self, stepName, regionName, variableName):
        odb_ = self.odb
        step = odb_.steps[stepName]
        Houtput = np.array(step.historyRegions[regionName].historyOutputs[variableName].data)
        time = Houtput[:, 0]        # First column is 'time' (or arc length for Riks)
        data = Houtput[:, 1]        # Second column is the variable data

        output = {
            'time': np.array(time),         # I've keyed this as 'time', but really it's arc length if this is a Riks step
            'data': np.array(data)
        }

        return output




    def getLPFs(self, stepName):
        """
        Extracts Load Proportionality Factors (LPFs) and corresponding arc lengths from a Riks analysis step in an Abaqus ODB file.
        Parameters
        ----------
        stepName : str
            The name of the analysis step from which to extract LPFs. This step must use the Riks procedure.
        Returns
        -------
        dict
            A dictionary containing:
                - 'arcLength': numpy.ndarray
                    Array of arc length values from the Riks step.
                - 'LPFs': numpy.ndarray
                    Array of Load Proportionality Factors corresponding to the arc lengths.
        Raises
        ------
        ValueError
            If the specified step is not a Riks step or does not contain LPFs.
        Notes
        -----
        This function assumes that the ODB object (`self.odb`) is already opened and accessible.
        The LPF data is extracted from the history output of the 'Assembly ASSEMBLY' region.
        """

        
        odb_ = self.odb
        step = odb_.steps[stepName]

        if 'RIKS' in step.procedure:     
            out = self.HoutputFromRgn(stepName, 'Assembly ASSEMBLY', 'LPF')
            output = {
                'arcLength': out['time'],        
                'LPFs': out['data']
            }
            return output
        else:
            raise ValueError("The specified step '{}' is not a Riks step or does not contain LPFs.".format(stepName))
                  
    def getRegionFromSet(self, setName, instanceName=None):
            """
            Retrieves an Abaqus odb.Region object corresponding to a specified node set or element set name.

            Parameters
            ----------
            setName : str
                The name of the node set or element set to retrieve.

            Returns
            -------
            odb.Region
                The Abaqus odb.Region object corresponding to the specified set.

            Raises
            ------
            ValueError
                If the specified set does not exist in the ODB file.
            """
            odb_ = self.odb
            if not instanceName:
                try:
                    region = odb_.rootAssembly.nodeSets[setName.upper()]
                    return region
                except KeyError:
                    pass  # Not a node set, try element sets

                try:
                    region = odb_.rootAssembly.elementSets[setName.upper()]
                    return region
                except KeyError:
                    raise ValueError("Set '{}' not an element or node set.".format(setName))
                
            else:
                try:
                    instance = odb_.rootAssembly.instances[instanceName.upper()]
                except KeyError:
                    raise ValueError("Instance '{}' not found in the output database.".format(instanceName))
                
                try:
                    region = instance.nodeSets[setName.upper()]
                    return region
                except KeyError:
                    pass  # Not a node set, try element sets

                try:
                    region = instance.elementSets[setName.upper()]
                    return region
                except KeyError:
                    raise ValueError("Set '{}' not an element or node set in instance '{}'.".format(setName, instanceName))