import os



EXCEPTIONS = ['load_list_generator.py', 'load_list.txt', 'largeimg']

def get_relative_path(base_directory, file_path):
    return "engine/"+os.path.relpath(file_path, base_directory)

def write_load_lists(directory):
    script_directory = os.path.dirname(os.path.abspath(__file__))
    full_paths = []
    for root, dirs, files in os.walk(directory):
        file_paths = []
        for file in files:
            file_path = os.path.join(root, file)
            extension = os.path.splitext(file)[1][1:].lower()
            if os.path.basename(file) not in EXCEPTIONS:
                file_paths.append(get_relative_path(script_directory, file_path))
        # Now we write our output to a file called load_list.txt in the current directory we're in
        if os.path.basename(root) not in EXCEPTIONS:
            with open(root+'/load_list.txt', 'w') as f:
                for path in file_paths:
                    full_paths.append(path)
                    p = path + '\n'
                    f.write(p)
                    # print(p)
                for dir in dirs:
                    p = get_relative_path(script_directory, root+"/"+dir)+"/"
                    full_paths.append(p)
                    f.write(p + '\n')
                    # print(p)

        # Then write to a file called everything.txt in same directory as this script
        with open(script_directory+'/everything.txt', 'w') as f:
            for path in full_paths:
                f.write(path + '\n')
                print(path)

if __name__ == "__main__":
    script_directory = os.path.dirname(os.path.abspath(__file__))
    file_paths = write_load_lists(script_directory)
    print("Done!")

