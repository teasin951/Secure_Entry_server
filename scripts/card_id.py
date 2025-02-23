import sys

def get_manufacturer_name():
    while True:
        name = input("Enter site identification name (ex. Company Ltd., max 16 characters): ").strip()
        if len(name) == 0:
            print("Error: Name cannot be empty.")
            continue
        elif len(name) > 16:
            print("Error: Max 16 characters.")
            continue
        
        # Truncate to 16 characters
        truncated = name[:16]
        
        # Check ASCII encoding
        try:
            truncated.encode('ascii')
        except UnicodeEncodeError:
            print("Error: Name must contain only ASCII characters.")
            continue
        
        # Pad with spaces if necessary
        return truncated.ljust(16, '\0')
        

def create_cardID( manufacturer ):
    # Get manufacturer name in 16-byte ASCII format
    manufacturer = bytes(manufacturer, 'ascii')

    # No other are currently supported
    mutual_auth = int("1100101000000010", 2).to_bytes(2)
    communication_enc = bytes(0x02)

    # Customer ID is currently not checked at the reader
    # it can be written to the card though, still, defaults to zeores
    customer_id = int("0", 2).to_bytes(4)

    # Key version is not currently checked, defaults to 1
    key_version = bytes(1)

    return manufacturer + mutual_auth + communication_enc + customer_id + key_version
    

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1] + "/CardID.bin"

    card_id = create_cardID( get_manufacturer_name() )

    with open(output_file, 'wb') as f:
        f.write(card_id)

    print(f"Data successfully written to {output_file}")
