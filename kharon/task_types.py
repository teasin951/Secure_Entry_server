from mqtt import MQTTHandler
import cbor2
from cbor import construct_cbor_whitelist, construct_cbor_remove_array
import json

# TODO document functions


def serialize_CardID(card_id):
    manufacturer = bytearray(16)
    mutual_auth = bytearray(2)
    comm_enc = bytearray(1)
    customer_id = bytearray(4)
    key_version = bytearray(1)

    manufacturer[:len(card_id['manufacturer'])] = card_id['manufacturer'].encode('ascii')
    mutual_auth[:]  = bytes.fromhex(card_id['mutual_auth'].lstrip('\\x'))
    comm_enc[:]     = bytes.fromhex(card_id['comm_enc'].lstrip('\\x'))
    # The system currently does not utilize customer_id
    key_version[:]  = bytes([card_id['key_version']])

    return manufacturer + mutual_auth + comm_enc + customer_id + key_version


def serialize_PACSO(pacso):
    version_major = bytearray(1)
    version_minor = bytearray(1)
    site_code     = bytearray(5)
    credential_id = bytearray(8)
    reissue_code  = bytearray(1)
    pin_code      = bytearray(4)
    customer_spec = bytearray(20)

    version_major[:] = bytes([pacso['version_major']])
    version_minor[:] = bytes([pacso['version_minor']])

    # DB allows to not have precise length, thus we left pad the rest
    site_striped = pacso['site_code'].lstrip('\\x')
    site_code[ 5 - int(len(site_striped)/2) :] = bytes.fromhex(site_striped)

    # credential id is currently not used
    reissue_code[:]  = bytes([pacso['reissue_code']])
    # pin_code is currently not used

    # DB allows to not have precise length, thus we left pad the rest
    cust_striped = pacso['customer_specific'].lstrip('\\x')
    customer_spec[ 20 - int(len(cust_striped)/2) :] = bytes.fromhex(cust_striped)

    return version_major + version_minor + site_code + credential_id + reissue_code + pin_code + customer_spec



def handle_config_update(dict_payload, mqtthandler):
    # -- Reformat the payload to what devices expect --
    # Hex numbers have to be parsed into bytes
    config = dict_payload['config']

    config['APPVOK'] = int(config['APPVOK'].lstrip('\\x'), 16)
    config['OCPSK']  = int(config['OCPSK'].lstrip('\\x'), 16)
    config['CardID'] = serialize_CardID(config['CardID'])
    config['PACSO'] = serialize_PACSO(config['PACSO'])

    # Publish config for all specified readers
    for reader in dict_payload['devices']['readers']:
        reader_conf = config
        reader_conf['zone'] = reader['zone']

        mqtthandler.publish_message(
            reader['topic'], 
            bytearray(cbor2.dumps(reader_conf)),
            qos=2, retain=True
        )

    # Publish config for all specified registrators
    for registrator in dict_payload['devices']['registrators']:
        registrator_conf = config
        registrator_conf['APPMOK'] = int(registrator['APPMOK'].lstrip('\\x'), 16)

        mqtthandler.publish_message(
            registrator['topic'], 
            bytearray(cbor2.dumps(registrator_conf)),
            qos=2, retain=True
        )


def task_whitelist_full(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray(construct_cbor_whitelist(dict_payload['whitelist'])),
        qos=2, retain=True
    )


def task_whitelist_add(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray(construct_cbor_whitelist(dict_payload['whitelist'])),
        qos=2, retain=False
    )


def task_whitelist_remove(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray(construct_cbor_remove_array(dict_payload['UIDs'])),
        qos=2, retain=False
    )


def task_personalize(dict_payload, mqtthandler:MQTTHandler):
    # TODO personalization UID handeling!!!
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray([0x1E]),
        qos=2, retain=False
    )


def task_depersonalize(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray([0xDE]),
        qos=2, retain=False
    )


def task_delete_app(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        dict_payload['topic'], 
        bytearray([0xFF]),
        qos=2, retain=False
    )


def task_dynsec(dict_payload, mqtthandler:MQTTHandler):
    mqtthandler.publish_message(
        "$CONTROL/dynamic-security/v1", 
        json.dumps(dict_payload),
        qos=2, retain=False
    )


def task_config(dict_payload, mqtthandler:MQTTHandler):
    handle_config_update(dict_payload, mqtthandler)


def task_remove_config(dict_payload, mqtthandler:MQTTHandler):
    # Send empty message with retain set to true to delete retained message
    mqtthandler.publish_message(
        dict_payload['topic'], 
        payload=None,
        qos=2, retain=True
    )
    

def carry_out_task(task, mqtthandler:MQTTHandler):

    print("Type: ", task['task_type'])
    print("Payload: ", task['payload'])
    print("")


    match task['task_type']:
        case "whitelist_full":
            task_whitelist_full(task['payload'], mqtthandler)

        case "whitelist_add":
            task_whitelist_add(task['payload'], mqtthandler)

        case "whitelist_remove":
            task_whitelist_remove(task['payload'], mqtthandler)

        case "personalize":
            task_personalize(task['payload'], mqtthandler)

        case "depersonalize":
            task_depersonalize(task['payload'], mqtthandler)

        case "delete_app":
            task_delete_app(task['payload'], mqtthandler)

        case "DynSec":
            task_dynsec(task['payload'], mqtthandler)

        case "config":
            task_config(task['payload'], mqtthandler)

        case "remove_config":
            task_remove_config(task['payload'], mqtthandler)

    return True
