import re
import csv
import os

count = 0


def extract_values(rule, pattern):
    # pattern = r'(?<=\W|^)(offset|depth|distance|within|nocase|http_raw_uri|http_raw_header|http_cookie|http_raw_cookie|http_client_body|http_raw_body|http_param|http_method|http_version|http_stat_code|http_stat_msg|http_raw_request|http_raw_status|http_trailer|http_raw_trailer|http_true_ip|http_version_match|http_num_headers|http_num_trailers|http_num_cookies|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|pkt_data|raw_data|file_data|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)(?=\W|$)\b'
    #pattern = r'(offset|depth|distance|within|http_true_ip|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)'
    #pattern = r'(fragbits|flow|fragoffset|ttl|tos|id|ipopts|ip_proto|flags|flowbits|file_type|seq|ack|window|itype|icode|icmp_id|icmp_seq|rpc|stram_reassemble|stream_size|offset|depth|distance|within|http_true_ip|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)'
    #pattern = r'(fragbits|fragoffset|ttl|tos|id|ipopts|ip_proto|flags|flowbits|file_type|seq|ack|window|itype|icode|icmp_id|icmp_seq|rpc|stram_reassemble|stream_size|offset|depth|distance|within|http_true_ip|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)'

    global count

    # Extracting the required values using regex
    proto = rule.split()[1]
    in_net = rule.split()[2]
    in_port = rule.split()[3]
    direction = rule.split()[4]
    out_net = rule.split()[5]
    out_port = rule.split()[6]
    content = re.search(r'(content:"[^"]+")', rule)
    flow = re.search((r'(flow:[^;]+;)'),rule)
    flow_value = flow.group(1) if flow is not None else "Not found"
    flowbits = re.search((r'(flowbits:[^;]+;)'),rule)
    flowbits_value = flowbits.group(1) if flowbits is not None else "Not found"
    multi = re.search(r"content.*?content", rule)
    # flag = re.match(pattern, rule, re.IGNORECASE)

    matches = re.finditer(pattern, rule)
    found = False

    for match in matches:
        start, end = match.span()
        if (start == 0 or not rule[start - 1].isalnum()) and (end == len(rule) or not rule[end].isalnum()):
            found = True
            break

    if found:
        count += 1

    if proto and in_net and in_port and direction and out_net and out_port and content and not found and not multi:
        return [proto, in_net, in_port, direction, out_net, out_port, content.group(1), flow_value, flowbits_value]
    else:
        return None


# Reading the rules from the file
cwd=os.getcwd()
ip_rel_path = 'rules/rules/v2.9/rules/rulemain.rules'
ip_abs_path = os.path.join(cwd,ip_rel_path)
with open(ip_abs_path, "r") as file:
    rules = file.readlines()

pattern = '(stream_reassemble|stream_size|rpc|icmp_seq|icmp_id|icode|itype|window|ack|seq|file_type|flags|ip_proto|ipopts|tos|ttl|fragoffset|fragbits|offset|depth|distance|within|http_true_ip|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)'
#pattern = '(fragbits|flow|fragoffset|ttl|tos|id|ipopts|ip_proto|flags|flowbits|file_type|seq|ack|window|itype|icode|icmp_id|icmp_seq|rpc|stream_reassemble|stream_size|offset|depth|distance|within|http_true_ip|http_header_test|http_trailer_test|bufferlen|isdataat|dsize|pcre|regex|js_data|vba_data|base64_decode|base64_data|byte_extract|byte_test|byte_math|byte_jump|ber_data|ber_skip|ssl_state|ssl_version|dce_iface|dce_opnum|dce_stub_data|sip_method|sip_header|sip_body|sip_stat_code|sd_pattern|asn1|cvs|md5|sha256|sha512|gtp_info|gtp_type|gtp_version|dnp3_func|dnp3_ind|dnp3_obj|dnp3_data|cip_attribute|cip_class|cip_conn_path_class|cip_instance|cip_req|cip_rsp|cip_service|cip_status|enip_command|enip_req|enip_rsp|iec104_apci_type|iec104_asdu_func|modbus_data|modbus_func|modbus_unit|s7commplus_content|s7commplus_func|s7commplus_opcode)'
#my_list = pattern[1:-1].split('|')
#rejoined_pattern='(' + '|'.join(my_list) + ')'
#for index in range(min(21, len(my_list))):
    #removed_element = my_list.pop(index)
    #rejoined_pattern='(' + '|'.join(my_list) + ')'

    # Processing each rule and saving the extracted values to a list
extracted_values = []
filtered_rules = []
for rule in rules:
    #values = extract_values(rule, rejoined_pattern)
    # if line beginsn with '#' then remobve hash and continue to extra features
    if rule.startswith("#"):
        rule = rule[1:]
    values = extract_values(rule, pattern)
    if values:
        extracted_values.append(values)
        filtered_rules.append(rule)
        
# Saving the extracted values to a CSV file
op_rel_csvpath = 'rules/rulesmainv2_9april26.csv'
op_abs_csvpath = os.path.join(cwd,op_rel_csvpath)
with open(op_abs_csvpath, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    for row in extracted_values:
        writer.writerow(row)

op_rel_txtpath = 'rules/broken_rule_v2_9_april26.txt'
op_abs_txtpath = os.path.join(cwd,op_rel_txtpath)
with open(op_abs_txtpath, "w") as file:
    for rule in filtered_rules:
        file.write(rule)

print("Values saved to output.csv")
#print(f'removed_element: {removed_element}')
print(count)
print(f'Rule count: {len(filtered_rules)}')
#my_list.insert(index,removed_element)
