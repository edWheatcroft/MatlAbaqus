"""
A class to handle operations on Abaqus output databases (.odb files).
Can be used with or without the CAE kernel.
"""

from odbAccess import openOdb
from abaqusConstants import *
import numpy as np

class odb:


    def __init__(self, odb_path):
        """
        Initializes the odb class with the path to the .odb file.

        Parameters:
        -----------
        odb_path : str
            Path to the output database (.odb file).
        """
        odb_ = openOdb(odb_path)
        if odb_ is None:
            raise FileNotFoundError("Could not open ODB file at {}. Please check the path and try again.".format(odb_path))
        

        self.odb = odb_
        self.odb_path = odb_path
        



    def close(self):
        """
        Closes the ODB file.
        """
        if self.odb is not None:
            self.odb.close()
            self.odb = None
        else:
            raise RuntimeError("ODB file is already closed or was never opened.")
        


    def getSingleFOutput(self, step_name, nodeSetName, variable_name, component):
        '''
        Extracts field output data for a specific variable and component at a single node set from a given step in an Abaqus ODB file.
        Parameters
        ----------
        step_name : str
            The name of the analysis step from which to extract data.
        nodeSetName : str
            The name of the node set from which to extract data. Must be a valid node set at the assembly level.
        variable_name : str
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
        step = odb_.steps[step_name]

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


            dataField = frame.fieldOutputs[variable_name]
            subset = dataField.getSubset(region=node_set)
            nodeData = subset.values[0]                     # Gives us a FieldValue obect. Index is zero because we assume single node in the set
            data = nodeData.data[component-1]               # .data is a tuple of the vector components. nodeData also has a load of other handy fields, e.g the invariants etc.
            dataSeries.append(data)

        output = {
            'time': np.array(timeSeries),                     # I've keyed this as 'time', but really it's arc length if this is a Riks step
            'data': np.array(dataSeries),
            'set': nodeSetName,
            'variable': variable_name + str(component),
        }

        
        return output
    


    def getLPFs(self, step_name):
        """
        Extracts Load Proportionality Factors (LPFs) and corresponding arc lengths from a Riks analysis step in an Abaqus ODB file.
        Parameters
        ----------
        step_name : str
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
        step = odb_.steps[step_name]

        if 'RIKS' in step.procedure:     
            lpfData = np.array(step.historyRegions['Assembly ASSEMBLY'].historyOutputs['LPF'].data)
            arcLength = lpfData[:, 0]  # First column is arc length
            LPFs = lpfData[:, 1]        # Second column is the Load Path

            output = {
                'arcLength': np.array(arcLength),
                'LPFs': np.array(LPFs)
            }

            return output
        else:
            raise ValueError("The specified step '{}' is not a Riks step or does not contain LPFs.".format(step_name))
        
        
