from bitarray import bitarray
import secrets
import matplotlib.pyplot as plt
from scipy.stats import chisquare
from collections import Counter
import openpyxl
import math
import random
import itertools

combinations = list(itertools.product(range(128), repeat=3))
all_possible_combo_raw = [list(comb) for comb in combinations]

def replicate_last_element_concatenate(lst, n):
    last_element = lst[-1]
    replicated_list = [last_element] * n
    final_list = lst + replicated_list
    return final_list

all_possible_combo = []

for i in range(len(all_possible_combo_raw)):
    all_possible_combo.append(replicate_last_element_concatenate(all_possible_combo_raw[i], 56))

# ! H3 D-Vector Generator 
def generate_D_vector(depth, size):
    values = []
    while len(values) < depth:
      value = random.randint(0, (2 ** size) -1)
      if value not in values:
        values.append(value)
    return values

# ! H3 Hash Function

def custom_hash(key: str, D_vector: list, seed: int = 0) -> int:
    result = seed  # initialize the result variable with the seed value
    bitmask_0 = 0b0000000
    bitmask_1 = 0b1111111

    # Loop through each character in the key string
    for i in range(len(key)):
        bit = int(key[i])
        if (bit):
            b_extended = bitmask_1
        else:
            b_extended = bitmask_0
        temp = b_extended & D_vector[i]
        # Perform the bitwise AND operation with the result
        result ^= temp

    return result

# ! Bloom Filter Class
class BloomFilter(object):
    def __init__(self, items_count, fp_prob, D_vector):

        self.fp_prob = fp_prob
        self.size = self.get_size(items_count, fp_prob)
        self.hash_count = self.get_hash_count(self.size, items_count)
        self.bit_array = bitarray(self.size)
        self.bit_array.setall(0)
        self.d_vec = D_vector
  
    def add(self, item):
        '''
        Add an item in the filter
        '''
        digests = []
        for i in range(self.hash_count):
            item_bytes = item.encode("utf-8")
            digest = custom_hash(item, self.d_vec, i) % self.size
            digests.append(digest)
            # set the bit True in bit_array
            self.bit_array[digest] = True
  
    def check(self, item):
        for i in range(self.hash_count):
            #digest = mmh3.hash(item, i) % self.size
            #item_bytes = item.encode("utf-8")
            digest = custom_hash(item, self.d_vec, i) % self.size
            # print(digest)
            if self.bit_array[digest] == False:
                return False
        return True
    def get_array(self):
        return self.bit_array
    @classmethod
    def get_size(self, n, p):
        m = -(n * math.log(p))/(math.log(2)**2)
        return int(m)
  
    @classmethod
    def get_hash_count(self, m, n):
        k = (m/n) * math.log(2)
        return int(k)

# !!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!
# * defining the specs
number_of_elements = 8
false_positive_rate = 0.001
data_bytes = 7
header_index = 3

prev_rate = 1

def process(n, p, data_bits, h):
    # * calculating the size of the bloom filter
    m = -(n * math.log(p))/(math.log(2)**2)
    # print ("size of m is ", int(m))
    
    # * calculating the number of hash functions
    k = (m/n) * math.log(2)
    # print ("Number of hash function is ", int(k))
    
    total_input_length = data_bits * 8 + h
    size =  math.ceil(math.log(m,2))
    # print ("output of the hash function is ", size)
    # print ("Size of each data and depth of D will be ", total_input_length)
    
    D_vector = generate_D_vector(total_input_length, size)
    
    # # * Save the values to a file
    filename1 = "values_for_hashing.txt"
    with open(filename1, "w") as f:
        for value in D_vector:
            f.write(str(value) + "\n")
    
    # Load the values from the file
    loaded_values = []
    with open(filename1, "r") as f:
        for line in f:
            loaded_values.append(int(line.strip()))
    
    D = loaded_values
    
    data = []
    with open("data_for_bloom.txt", "r") as f:
        for line in f:
            data.append(line.strip())
    
    bloomf = BloomFilter(n,p,D)
    # print("Size of bit array:{}".format(bloomf.size))
    # print("False positive Probability:{}".format(bloomf.fp_prob))
    # print("Number of hash functions:{}".format(bloomf.hash_count))
    
    for item in data:
        bloomf.add(item)
    
    samples = 10000
    test_data = [format(random.getrandbits(59), '059b') for _ in range(samples)]
    
    false_positive = 0
    
    for word in test_data:
        if bloomf.check(word):
            if word not in data:
                # print("'{}' is a false positive!".format(word))
                false_positive += 1
            else:
                pass
                # print("'{}' is probably present!".format(word))
        else:
            pass
            # print("'{}' is definitely not present!".format(word))
    
    rate = false_positive / samples * 100

    current_rate = rate / 100

    global prev_rate

    if (current_rate < prev_rate):
        print("False positive rate: {}%".format(rate))
        print(bloomf.bit_array)
        with open('final_bloom_value.txt', "w") as f:
            f.write(str(rate) + "\n")
            f.write(str(bloomf.bit_array) + "\n")
            for value in D:
                f.write(str(value) + "\n")

        prev_rate = current_rate

for i in range(10000):
    process(8, false_positive_rate, 7, 3)

# # * calculating the size of the bloom filter
# m = -(number_of_elements * math.log(false_positive_rate))/(math.log(2)**2)
# print ("size of m is ", int(m))

# # * calculating the number of hash functions
# k = (m/number_of_elements) * math.log(2)
# print ("Number of hash function is ", int(k))

# total_input_length = data_bytes * 8 + header_index
# size =  math.ceil(math.log(m,2))
# print ("output of the hash function is ", size)
# print ("Size of each data and depth of D will be ", total_input_length)

# D_vector = generate_D_vector(total_input_length, size)

# # * Save the values to a file
# filename1 = "values_for_hashing.txt"
# with open(filename1, "w") as f:
#     for value in D_vector:
#         f.write(str(value) + "\n")

# # Load the values from the file
# loaded_values = []
# with open(filename1, "r") as f:
#     for line in f:
#         loaded_values.append(int(line.strip()))

# D = loaded_values

# data = []
# with open("data_for_bloom.txt", "r") as f:
#     for line in f:
#         data.append(line.strip())

# bloomf = BloomFilter(number_of_elements,false_positive_rate)
# print("Size of bit array:{}".format(bloomf.size))
# print("False positive Probability:{}".format(bloomf.fp_prob))
# print("Number of hash functions:{}".format(bloomf.hash_count))

# for item in data:
#     bloomf.add(item)

# samples = 10000
# test_data = [format(random.getrandbits(59), '059b') for _ in range(samples)]

# false_positive = 0

# for word in test_data:
#     if bloomf.check(word):
#         if word not in data:
#             # print("'{}' is a false positive!".format(word))
#             false_positive += 1
#         else:
#             pass
#             # print("'{}' is probably present!".format(word))
#     else:
#         pass
#         # print("'{}' is definitely not present!".format(word))

# rate = false_positive / samples * 100
# print("False positive rate: {}%".format(rate))

# print(bloomf.bit_array)
