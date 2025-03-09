
import cbor2


# Create a single CBOR entry from arguments
def construct_cbor_entry( UID, TimeRules, TimeRulesCount ):
    data = [ UID ]

    for i in range(0, TimeRulesCount):
        data.append({"t": TimeRules[i]})

    return cbor2.dumps(data)


def print_construct_cbor_entry():
    UID = 0x11223344556677
    TimeRules = [ 0x7C06222030, 0x6C08400910 ]
    full_cbor = bytes(0) 

    for i in range(0, 3):
        full_cbor += construct_cbor_entry(UID, TimeRules, i) 

        print(f"Encoded entry: {construct_cbor_entry(UID, TimeRules, i).hex()}")
        print(f"Decoded entry: {cbor2.loads(construct_cbor_entry(UID, TimeRules, i))}")

    print(f"Full encoded entry: {full_cbor.hex()}")
    