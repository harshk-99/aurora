"""compare raw bytes with hex data as inpiuts and prints the mismatches"""
import sys
import getopt
import os

file1 = os.path.abspath("./output/1C1Tpatternmatcher_rawbytespayload.hex")
file2 = os.path.abspath("./output/1C1Twopatternmatcher_rawbytespayload.hex")

with open(file1, 'rb') as file1, open(file2, 'rb') as file2:
    bytes1 = file1.read(200)
    bytes2 = file2.read(200)
    
    for i, (b1, b2) in enumerate(zip(bytes1, bytes2)):
        if b1 != b2:
           print(f"Byte {i}: {b1:02X} != {b2:02X} ({chr(b1)} != {chr(b2)})") 