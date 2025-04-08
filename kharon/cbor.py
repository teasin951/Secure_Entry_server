
import cbor2


def construct_time_rule(allow_from, allow_to, week_days):
    """ From json whitelist parameters construct int64 for CBOR

    Args:
        allow_from (string): as received from DB
        allow_to (string): as received from DB
        week_days (string): as received from DB
    """

    week_day_mask = int(week_days.lstrip('\\x'), 16)

    split_from = allow_from.split(':')
    split_to   = allow_to.split(':')

    from_hour   = int(split_from[0], 10)
    from_minute = int(split_from[1], 10)
    to_hour     = int(split_to[0],   10)
    to_minute   = int(split_to[1],   10)

    int_time_rule = (
        (week_day_mask << 32) |
        (from_hour << 24) |
        (from_minute << 16) |
        (to_hour << 8) |
        to_minute
    )

    return int_time_rule


def construct_time_rules(time_rules):
    """ Create array of time rules

    Args:
        time_rules (array): array of dict objects describing time rules from the DB

    Returns:
        array: array of time rules as int64
    """
    out = []
    for rule in time_rules:
        out.append( construct_time_rule(rule['allow_from'], rule['allow_to'], rule['week_days']) )
        
    return out


def construct_cbor_entry(UID, time_rules):
    """ Create a single CBOR whitelist entry from arguments

    Args:
        UID (string): as received from DB
        time_rules (array): array of int64 time rule numbers

    Returns:
        CBOR: CBOR array describing a single whitelist entry as needed by the readers
    """

    # The result is an array, thus we start with an array
    data = [ int(UID.lstrip('\\x'), 16) ]

    for rule in time_rules:
        data.append({"t": rule})

    return cbor2.dumps(data)


def construct_cbor_whitelist(whitelist):
    """ Create a CBOR whitelist for the readers from the list of rules

    Args:
        whitelist (array): whitelist from the DB

    Returns:
        CBOR: constructed whitelist
    """

    cbor_whitelist = []
    for entry in whitelist:
        time_rules = construct_time_rules(entry['time_rules'])
        cbor_whitelist += construct_cbor_entry(entry['UID'], time_rules)

    return cbor_whitelist


def construct_cbor_remove_array(UIDs_array):
    """ Create list for removal from whitelist

    Args:
        UIDs_array (array): array of UIDs to be put on the list 

    Returns:
        CBOR: CBOR list of UIDs to remove
    """

    cbor_whitelist = []
    for entry in UIDs_array:
        cbor_whitelist += construct_cbor_entry(entry, []) 

    return cbor_whitelist



# TODO only for testing, move this
def print_construct_cbor_entry():
    UID = 0x11223344556677
    TimeRules = [ 0x7C06222030, 0x6C08400910 ]
    full_cbor = bytes(0) 

    for i in range(0, 3):
        full_cbor += construct_cbor_entry(UID, TimeRules, i) 

        print(f"Encoded entry: {construct_cbor_entry(UID, TimeRules, i).hex()}")
        print(f"Decoded entry: {cbor2.loads(construct_cbor_entry(UID, TimeRules, i))}")

    print(f"Full encoded entry: {full_cbor.hex()}")
    