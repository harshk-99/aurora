# LIMITATIONS:
# no character is allowed after the label i.e. 
# THIS IS OK 
# .label:
# THIS IS NOT OK
# .label # comment
import sys
import getopt
import os

#input_file = os.path.abspath("./aurora/sw/patterncounter.s")
#output_file = os.path.abspath("./aurora/initialization/copy_lab11.txt")

inst_type_dict = {
    "R-TYPE": ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"],
    "I-TYPE": ["addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai", "ld", "jalr", "lb", "lh", "lw", "lbu", "lhu"],
    "S-TYPE": ["sd", "sb", "sh", "sw"],
    "B-TYPE": ["beq", "bne", "blt", "bge", "bltu", "bgeu"],
    "J-TYPE": ["jal"],
    "P-TYPE": ["li", "j", "mv", "jr"]
}

opcode_dict = {
    "1101111": ["jal"],
    "1100111": ["jalr"],
    "1100011": ["beq", "bne", "blt", "bge", "bltu", "bgeu"],
    "0000011": ["lb", "lh", "lw", "lbu", "lhu", "ld"],
    "0100011": ["sb", "sh", "sw", "sd"],
    "0010011": ["addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai"],
    "0110011": ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"]
}

func3_dict = {
    "000": ["add", "sub", "addi", "beq", "jalr"],
    "001": ["sll", "slli", "bne"],
    "010": ["slti", "slt"],
    "011": ["sltiu", "sltu", "ld", "sd", "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw"],
    "100": ["blt", "xori", "xor"],
    "101": ["bge", "srli", "srai", "srl", "sra"],
    "110": ["bltu", "ori", "or"],
    "111": ["bgeu", "andi", "and"]
}

func7_dict = {
    "0000000": ["slli", "srli", "add", "sll", "slt", "sltu", "xor", "srl", "or", "and"],
    "0100000": ["srai", "sub", "sra"]
}

abi_dict = {
    "00000": ["zero", "x0"],
    "00001": ["ra", "x1"],
    "00010": ["sp", "x2"],
    "00011": ["gp", "x3"],
    "00100": ["tp", "x4"],
    "00101": ["t0", "x5"],
    "00110": ["t1", "x6"],
    "00111": ["t2", "x7"],
    "01000": ["s0", "fp", "x8"],
    "01001": ["s1", "x9"],
    "01010": ["a0", "x10"],
    "01011": ["a1"],
    "01100": ["a2"],
    "01101": ["a3"],
    "01110": ["a4"],
    "01111": ["a5"],
    "10000": ["a6"],
    "10001": ["a7"],
    "10010": ["s2"],
    "10011": ["s3"],
    "10100": ["s4"],
    "10101": ["s5"],
    "10110": ["s6"],
    "10111": ["s7"],
    "11000": ["s8"],
    "11001": ["s9"],
    "11010": ["s10"],
    "11011": ["s11"],
    "11100": ["t3"],
    "11101": ["t4"],
    "11110": ["t5"],
    "11111": ["t6"],
}

pseudo_dict = {
    "li": lambda rd, val: "ori " + rd + " zero " + val,
    "mv": lambda rd, rs: "addi " + rd + " " + rs + " 0",
    "j": lambda offset: "jal zero " + offset,
    "jr": lambda rs: "jalr zero " + "0(" + rs + ")"
}


def parseRType(parts):
    opcode = list(opcode_dict.keys())[
        [(i, opcode_list.index(parts[0])) for i, opcode_list in enumerate(list(opcode_dict.values())) if parts[0] in opcode_list][0][0]]
    func3 = list(func3_dict.keys())[
        [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
    rd = list(abi_dict.keys())[
        [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
    rs1 = list(abi_dict.keys())[
        [(i, abi_list.index(parts[2])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[2] in abi_list][0][0]]
    rs2 = list(abi_dict.keys())[
        [(i, abi_list.index(parts[3])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[3] in abi_list][0][0]]
    func7 = list(func7_dict.keys())[
        [(i, func7_list.index(parts[0])) for i, func7_list in enumerate(list(func7_dict.values())) if parts[0] in func7_list][0][0]]
    return func7 + rs2 + rs1 + func3 + rd + opcode


def parseIType(parts):
    opcode = list(opcode_dict.keys())[
        [(i, opcode_list.index(parts[0])) for i, opcode_list in enumerate(list(opcode_dict.values())) if parts[0] in opcode_list][0][0]]
    if (opcode == "0010011"):
        func3 = list(func3_dict.keys())[
            [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
        rd = list(abi_dict.keys())[
            [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
        rs1 = list(abi_dict.keys())[
            [(i, abi_list.index(parts[2])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[2] in abi_list][0][0]]
        if (parts[0] == "slli" or parts[0] == "srli" or parts[0] == "srai"):
            immd12 = list(func7_dict.keys())[
                [(i, func7_list.index(parts[0])) for i, func7_list in enumerate(list(func7_dict.values())) if parts[0] in func7_list][0][0]] + getBinary(int(parts[3]), 5)
        else:
            immd12 = getBinary(int(parts[3]), 12)
    elif (opcode == "0000011"):
        tmp_immd12, tmp_rs1 = parts[2].split("(")
        tmp_rs1 = tmp_rs1.strip(")")
        func3 = list(func3_dict.keys())[
            [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
        rd = list(abi_dict.keys())[
            [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
        rs1 = list(abi_dict.keys())[
            [(i, abi_list.index(tmp_rs1)) for i, abi_list in enumerate(list(abi_dict.values())) if tmp_rs1 in abi_list][0][0]]
        immd12 = getBinary(int(tmp_immd12), 12)
    else:
        tmp_immd12, tmp_rs1 = parts[2].split("(")
        tmp_rs1 = tmp_rs1.strip(")")
        func3 = list(func3_dict.keys())[
            [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
        rd = list(abi_dict.keys())[
            [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
        rs1 = list(abi_dict.keys())[
            [(i, abi_list.index(tmp_rs1)) for i, abi_list in enumerate(list(abi_dict.values())) if tmp_rs1 in abi_list][0][0]]
        immd12 = getBinary(int(tmp_immd12), 12)
    return immd12 + rs1 + func3 + rd + opcode


def parseSType(parts):
    opcode = list(opcode_dict.keys())[
        [(i, opcode_list.index(parts[0])) for i, opcode_list in enumerate(list(opcode_dict.values())) if parts[0] in opcode_list][0][0]]
    tmp_immd12, tmp_rs1 = parts[2].split("(")
    tmp_rs1 = tmp_rs1.strip(")")
    func3 = list(func3_dict.keys())[
        [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
    rs2 = list(abi_dict.keys())[
        [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
    rs1 = list(abi_dict.keys())[
        [(i, abi_list.index(tmp_rs1)) for i, abi_list in enumerate(list(abi_dict.values())) if tmp_rs1 in abi_list][0][0]]
    immd12 = getBinary(int(tmp_immd12), 12)
    return immd12[:7] + rs2 + rs1 + func3 + immd12[7:] + opcode


def parseBType(parts):
    opcode = list(opcode_dict.keys())[
        [(i, opcode_list.index(parts[0])) for i, opcode_list in enumerate(list(opcode_dict.values())) if parts[0] in opcode_list][0][0]]
    func3 = list(func3_dict.keys())[
        [(i, func3_list.index(parts[0])) for i, func3_list in enumerate(list(func3_dict.values())) if parts[0] in func3_list][0][0]]
    rs1 = list(abi_dict.keys())[
        [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
    rs2 = list(abi_dict.keys())[
        [(i, abi_list.index(parts[2])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[2] in abi_list][0][0]]
    immd12 = getBinary(int(parts[3]), 12)
    return immd12[0] + immd12[2:8] + rs2 + rs1 + func3 + immd12[8:] + immd12[1] + opcode


def parseJType(parts):
    opcode = list(opcode_dict.keys())[
        [(i, opcode_list.index(parts[0])) for i, opcode_list in enumerate(list(opcode_dict.values())) if parts[0] in opcode_list][0][0]]
    rd = list(abi_dict.keys())[
        [(i, abi_list.index(parts[1])) for i, abi_list in enumerate(list(abi_dict.values())) if parts[1] in abi_list][0][0]]
    immd20 = getBinary(int(parts[2]), 20)
    return immd20[0] + immd20[10:] + immd20[9] + immd20[1:9] + rd + opcode


def parsePType(parts):
    if len(parts) == 3:
        pseudo_inst = pseudo_dict[parts[0]](parts[1], parts[2])
    elif len(parts) == 2:
        pseudo_inst = pseudo_dict[parts[0]](parts[1])
    return assemble_riscv(pseudo_inst)


def getBinary(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)


def assemble_riscv(instruction):
    parts = instruction.split()
    inst_type = list(inst_type_dict.keys())[
        [(i, inst_list.index(parts[0])) for i, inst_list in enumerate(list(inst_type_dict.values())) if parts[0] in inst_list][0][0]]
    print(inst_type)
    # ins = func.get(parts[0])
    if (inst_type == "R-TYPE"):
        instr = parseRType(parts)
    elif (inst_type == "I-TYPE"):
        instr = parseIType(parts)
    elif (inst_type == "S-TYPE"):
        instr = parseSType(parts)
    elif (inst_type == "B-TYPE"):
        instr = parseBType(parts)
    elif (inst_type == "J-TYPE"):
        instr = parseJType(parts)
    elif (inst_type == "P-TYPE"):
        instr = parsePType(parts)
    else:
        raise Exception("Illegal Instruction")

    return instr


def print_all():
    print(block_names)

input_file = ''
output_file = ''

if len(sys.argv) == 1:
    print('Usage: python3 riscv_compiler.py -i <inputfile> -o <outputfile>')
    sys.exit()

try:
    opts, args = getopt.getopt(sys.argv[1:], "hi:o:", ["ifile=", "ofile="])
except getopt.GetoptError:
    print('Usage: python3 riscv_compiler.py -i <inputfile> -o <outputfile>')
    sys.exit(2)

for opt, arg in opts:
    if opt == '-h':
        print('Usage: python3 riscv_compiler.py -i <inputfile> -o <outputfile>')
        sys.exit()
    elif opt in ("-i", "--ifile"):
        input_file = arg
    elif opt in ("-o", "--ofile"):
        output_file = arg

# creating one more file that elaborate the entire program
appended_string = "_elaborate"
# Split the file path into directory, name, and extension
directory_path, file_name_with_ext = os.path.split(output_file)
file_name, file_ext = os.path.splitext(file_name_with_ext)
# Create the new file name with the appended string
elaborate_file_name = f"{file_name}{appended_string}{file_ext}"
elaborate_file_path = os.path.join(directory_path, elaborate_file_name)

inst_start_mem = 0
inst_count = 0
current_pc = inst_start_mem

block_names = {}
instructions = []
filename = input_file
with open(filename, "r") as file:
    for line in file:

        # Strip the line of leading and trailing whitespace
        stripped_line = line.strip()
        if (stripped_line != "" and stripped_line[0] != "#"):
            if stripped_line[-1] != ":":
                inst_count += 1
            else:
                block_names[stripped_line[:-1]] = inst_count + \
                    inst_start_mem
print_all()
bin_instruction_history = []
asm_instruction_history = []
program_counter = 0
with open(filename, "r") as file:
    for line in file:

        # remove the commas and trailing comments in the line
        stripped_line = line.replace(",","").split('#',1)[0]
        # Strip the line of leading and trailing whitespace
        stripped_line = stripped_line.strip()
        if (stripped_line != "" and stripped_line[0] != "#"):
            if (stripped_line[-1] != ":"):
                # Print assmebly code line
                print((stripped_line))
                for key, value in block_names.items():
                    #print("Jumping from ", current_pc , " to ", key , " ", value)
                    if key in stripped_line:
                        print("Jumping from ", program_counter,
                              " to ", key, " ", value)
                    stripped_line = stripped_line.replace(
                        key, str(value-program_counter))

                # generate binary of that assembly
                instructions.append(assemble_riscv(stripped_line))
                asm_instruction_history.append(stripped_line)
                print(program_counter, " ", asm_instruction_history[-1], instructions[-1])
                program_counter += 1


f = open(output_file, "w")
num_lines = len(instructions)
for i, inst in enumerate(instructions):
    # If it's not the last line, end it with a comma
    if i < num_lines - 1:
        f.write(f'{inst},\n')
    else:
        # If it's the last line, end it with a semicolon
        f.write(f'{inst};\n')
f.close()

assert len(asm_instruction_history) == len(instructions), f'assembly instructions are {len(asm_instruction_history)}, binary instructions are {len(instructions)}'
with open(elaborate_file_path, 'w', newline='') as file:
    file.write("{0: <3} {1: <30} {2: <20} {3: <12} {4: <34}\n".format("PC","labels","asm","hex","binary"))
    for index, elem2 in enumerate(asm_instruction_history):
        elem3 = instructions[index]
        hex_string = hex(int(elem3, 2))
        hex_string = "0x{:0>8}".format(hex_string[2:])
        if index in block_names.values():
            label = list(block_names.keys())[list(block_names.values()).index(index)]
            file.write("{0: <3} {1: <30} {2: <20} {3: <12} {4: <34}\n".format(index, label, elem2, hex_string, elem3))
        else:
            label = ""
            file.write("{0: <3} {1: <30} {2: <20} {3: <12} {4: <34}\n".format(index, label, elem2, hex_string, elem3))


print_all()
