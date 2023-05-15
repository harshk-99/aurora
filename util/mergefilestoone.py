import os
import shutil

cwd=os.getcwd()
source_folder_rel = 'rules/rules/v2.9/rules'
source_folder = os.path.join(cwd, source_folder_rel)
destination_file_rel = 'rules/rules/v2.9/rules/rulemain.rules'
destination_file = os.path.join(cwd,destination_file_rel)

# Iterate over the files in the source folder
for filename in os.listdir(source_folder):
    source_path = os.path.join(source_folder, filename)

    # Check if it's a file (and not a directory)
    if os.path.isfile(source_path):
        # Open the source file for reading
        with open(source_path, "rb") as src_file:
            # Open the destination file in append mode
            with open(destination_file, "ab") as dest_file:
                # Copy the contents of the source file to the destination file
                shutil.copyfileobj(src_file, dest_file)
