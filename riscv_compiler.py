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
    "00000": ["zero"],
    "00001": ["ra"],
    "00010": ["sp"],
    "00011": ["gp"],
    "00100": ["tp"],
    "00101": ["t0"],
    "00110": ["t1"],
    "00111": ["t2"],
    "01000": ["s0", "fp"],
    "01001": ["s1"],
    "01010": ["a0"],
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
        if (parts[0] == "slli" or parts[0] == "srli" or parts[0] == "slai"):
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


inst_start_mem = 0
inst_count = 0
block_names = {}
instructions = []
filename = "test.s"
with open(filename, "r") as file:
    for line in file:

        # Strip the line of leading and trailing whitespace
        stripped_line = line.strip()
        if (stripped_line != "" and stripped_line[0] != "#"):
            if stripped_line[-1] != ":":
                inst_count += 1
            elif (stripped_line[0] == "."):
                print([stripped_line[:-1], inst_count+2])
                block_names[stripped_line[:-1]] = inst_count + \
                    inst_start_mem + 2
program_counter = 0
with open(filename, "r") as file:
    for line in file:

        # Strip the line of leading and trailing whitespace
        stripped_line = line.strip()
        if (stripped_line != "" and stripped_line[0] != "#"):
            if (stripped_line[-1] != ":"):
                program_counter += 1

                for key, value in block_names.items():
                    stripped_line = stripped_line.replace(key, str(value))

                # Print assmebly code line
                print((stripped_line))

                # generate binary of that assembly
                instructions.append(assemble_riscv(stripped_line))

                # for formatting
                # bin_str = format(num, '032b')

            #     print(inst_count, end="    ")
            #     # adding the spaces for ez debug
            #     for i in range(len(bin_str)):

            #         if (i == 6 or i == 11 or i == 16 or i == 19 or i == 24):
            #             print(bin_str[i], end=" ")
            #         else:
            #             print(bin_str[i], end="")
            #     print("")

            # elif (stripped_line[0] == "."):
            #     print([stripped_line[:stripped_line.find(":")], inst_count+4])
            # #    block_names[stripped_line[:stripped_line.find(":")]] =(inst_count+1)*4+inst_start_mem

f = open("i_mem.bin", "w")
for inst in instructions:
    f.write(f'{inst}\n')
f.close()

print_all()
