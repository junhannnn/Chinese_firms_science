import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
import os

def execute_notebook(path, timeout=3600, kernel_name='python3'):
    """
    Execute a Jupyter Notebook file and save the output.

    Parameters:
        path (str): The file path of the notebook to execute.
        timeout (int): Maximum time (in seconds) allowed for each cell execution.
        kernel_name (str): Name of the kernel to use (e.g., 'python3').
    
    Returns:
        None
    """
    # Read the notebook from the specified path
    with open(path, 'r', encoding='utf-8') as f:
        notebook = nbformat.read(f, as_version=4)
    
    # Set up the ExecutePreprocessor with desired parameters
    ep = ExecutePreprocessor(timeout=timeout, kernel_name=kernel_name)
    
    # Execute the notebook
    try:
        notebook_dir = os.path.dirname(path)  # Extracts the directory from the full path
        ep.preprocess(notebook, {'metadata': {'path': notebook_dir}})
    except Exception as e:
        print(f"An error occurred during execution: {e}")
        raise

    # Save the executed notebook back to the same file
    with open(path, 'w', encoding='utf-8') as f:
        nbformat.write(notebook, f)
    
    print("Notebook executed and saved successfully.")