import cbor2
import os
from card_id import create_cardID


def create_PACSO():
    version = int("0000000100000001", 2).to_bytes(2)
    the_rest = int("0", 2).to_bytes(5+8+1+4+20)
    return version + the_rest 


def get_UID():
    while True:
        uid_input = input("Enter the 7-byte card UID (14 hexadecimal characters): ").strip()
        
        if len(uid_input) == 14 and all(c in "0123456789ABCDEFabcdef" for c in uid_input):
            uid = int(uid_input, 16) << 8  # Make it zero-terminated
            return uid
        else:
            print("Invalid input. Please enter exactly 14 hexadecimal characters (0-9, A-F).")

def random_UID():
    return int.from_bytes(os.urandom(7)) << 8


# Create a single CBOR entry from arguments
def construct_cbor_entry( UID, TimeRules, TimeRulesCount ):
    data = [ UID ]

    for i in range(0, TimeRulesCount):
        data.append({"t": TimeRules[i]})

    return cbor2.dumps(data)


def main():
    main_UID = get_UID()
    card_id  = create_cardID("TestName")
    pacso    = create_PACSO()
    
    setup = {
        "APPMOK": 0x11223344556677889900112233445566,
        "APPVOK": 0x11223344556677889900112233445566,
        "OCPSK": 0x11223344556677889900112233445566,
        "CardID": card_id,
        "PACSO": pacso,
        "Zone": 1
    }

    with open("test_setup.cbor", 'wb') as f:
        f.write( cbor2.dumps(setup) )
    

    # -- whitelist -- #

    test_UID = 0x1122334455667700
    TimeRules = [ 0x7C06222030, 0x6C08400910 ]

    full_cbor = bytes(0) 
    full_cbor += construct_cbor_entry(main_UID, TimeRules, 0) 
    full_cbor += construct_cbor_entry(test_UID, TimeRules, 2)

    with open("test_whitelist.cbor", 'wb') as f:
        f.write( full_cbor )


if __name__ == '__main__':
    main()


