def count_unbalanced_brackets(file_path):
    stack = []
    unbalanced_count = 0

    with open(file_path, 'r') as file:
        inside_multi_line_comment = False

        for line_number, line in enumerate(file, start=1):
            # Remove single-line comments
            line = line.split('//', 1)[0].rstrip()

            # Handle multi-line comments
            if '/*' in line:
                inside_multi_line_comment = True
            if '*/' in line:
                inside_multi_line_comment = False
                line = line.split('*/', 1)[-1].lstrip()

            if not inside_multi_line_comment:
                for char_number, char in enumerate(line, start=1):
                    if char in {'(', '[', '{'}:
                        stack.append((char, line_number, char_number))
                    elif char in {')', ']', '}'}:
                        if not stack:
                            unbalanced_count += 1
                            print(f"Unbalanced bracket at line {line_number}, position {char_number}")
                        else:
                            open_bracket, open_line, open_char = stack.pop()
                            if (char == ')' and open_bracket != '(') or \
                               (char == ']' and open_bracket != '[') or \
                               (char == '}' and open_bracket != '{'):
                                unbalanced_count += 1
                                print(f"Unbalanced bracket at line {line_number}, position {char_number}")

    # Check for any remaining open brackets
    while stack:
        open_bracket, open_line, open_char = stack.pop()
        unbalanced_count += 1
        print(f"Unbalanced bracket at line {open_line}, position {open_char}")

    print(f"Total unbalanced brackets: {unbalanced_count}")


# Example usage: replace 'YourJavaFile.java' with the path to your Java file
count_unbalanced_brackets('engine.pde')
