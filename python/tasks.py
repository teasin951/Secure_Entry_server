from mqtt import MQTTHandler
import cbor2
from cbor import construct_cbor_whitelist, construct_cbor_remove_array
import json
import logging


# TODO document functions


logger = logging.getLogger(__name__)


class TaskHandler:
    def __init__(self, dbconn, mqtthandler:MQTTHandler):
        self.conn = dbconn
        self.mqtthandler = mqtthandler
        # self.task_timeout = 10   # How long to wait before we delete pending task


    def carry_out_task(self, task):

        logger.debug('Type: %s, Payload: %s', str(task['task_type']), str(task['payload']))

        match task['task_type']:
            case "personalize":
                if( self.task_personalize(task['payload'], task['id_task']) ):
                    self.set_pending_task(task['id_task'])
                    return True

            case "depersonalize":
                if( self.task_depersonalize(task['payload'], task['id_task']) ):
                    self.set_pending_task(task['id_task'])
                    return True

            case "delete_app":
                if( self.task_delete_app(task['payload'], task['id_task']) ):
                    self.set_pending_task(task['id_task'])
                    return True

            case "whitelist_add":
                if( self.task_whitelist_add(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

            case "whitelist_remove":
                if( self.task_whitelist_remove(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

            case "whitelist_full":
                if( self.task_whitelist_full(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

            case "DynSec":
                if( self.task_dynsec(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

            case "config":
                if( self.task_config(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

            case "remove_config":
                if( self.task_remove_config(task['payload']) ):
                    self.finish_task(task['id_task'])
                    return True

        return False


    def handle_config_update(self, dict_payload):
        # -- Reformat the payload to what devices expect --
        # Hex numbers have to be parsed into bytes
        config = dict_payload['config']

        config['APPVOK'] = int(config['APPVOK'].lstrip('\\x'), 16)
        config['OCPSK']  = int(config['OCPSK'].lstrip('\\x'), 16)
        config['CardID'] = self.serialize_CardID(config['CardID'])
        config['PACSO']  = self.serialize_PACSO(config['PACSO'])

        # Publish config for all specified readers
        for reader in dict_payload['devices']['readers']:
            reader_conf = config
            reader_conf['Zone'] = reader['Zone']

            self.mqtthandler.publish_message(
                reader['topic'], 
                bytearray(cbor2.dumps(reader_conf)),
                qos=2, retain=True
            )

        # Publish config for all specified registrators
        for registrator in dict_payload['devices']['registrators']:
            registrator_conf = config
            registrator_conf['APPMOK'] = int(registrator['APPMOK'].lstrip('\\x'), 16)

            self.mqtthandler.publish_message(
                registrator['topic'], 
                bytearray(cbor2.dumps(registrator_conf)),
                qos=2, retain=True
            )

        return True


    def task_whitelist_full(self, dict_payload):
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray(construct_cbor_whitelist(dict_payload['whitelist'])),
            qos=2, retain=False
        )
        return True


    def task_whitelist_add(self, dict_payload):
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray(construct_cbor_whitelist(dict_payload['whitelist'])),
            qos=2, retain=False
        )
        return True


    def task_whitelist_remove(self, dict_payload):
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray(construct_cbor_remove_array(dict_payload['UIDs'])),
            qos=2, retain=False
        )
        return True


    def task_personalize(self, dict_payload, id_task):
        self.mqtthandler.wait_registrator_get_UID(
            dict_payload['username'], dict_payload['id_card'], id_task)
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray([0x1E]),
            qos=2, retain=False
        )
        return True


    def task_depersonalize(self, dict_payload, id_task):
        self.mqtthandler.wait_registrator_depersonalize(dict_payload['username'], id_task)
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray([0xDE]),
            qos=2, retain=False
        )
        return True


    def task_delete_app(self, dict_payload, id_task):
        self.mqtthandler.wait_registrator_depersonalize(dict_payload['username'], id_task)
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            bytearray([0xFF]),
            qos=2, retain=False
        )
        return True


    def task_dynsec(self, dict_payload):
        self.mqtthandler.publish_message(
            "$CONTROL/dynamic-security/v1", 
            json.dumps(dict_payload),
            qos=2, retain=False
        )
        return True


    def task_config(self, dict_payload):
        self.handle_config_update(dict_payload)
        return True


    def task_remove_config(self, dict_payload):
        # Send empty message with retain set to true to delete retained message
        self.mqtthandler.publish_message(
            dict_payload['topic'], 
            payload=None,
            qos=2, retain=True
        )
        return True
        

    def finish_task(self, id_task):
        with self.conn.cursor() as cur:
            cur.execute("""
                DELETE FROM task_queue
                WHERE id_task = %s;
            """, (id_task,))

        return True


    def set_pending_task(self, id_task):
        # TODO probably should have a timeout
        with self.conn.cursor() as cur:
            cur.execute("""
                UPDATE task_queue
                SET pending = TRUE
                WHERE id_task = %s;
            """, (id_task,))

        return True


    def serialize_CardID(self, card_id):
        manufacturer = bytearray(16)
        mutual_auth = bytearray(2)
        comm_enc = bytearray(1)
        customer_id = bytearray(4)
        key_version = bytearray(1)

        manufacturer[:len(card_id['manufacturer'])] = card_id['manufacturer'].encode('ascii')
        mutual_auth[:]  = bytes.fromhex(card_id['mutual_auth'].lstrip('\\x'))
        comm_enc[:]     = bytes.fromhex(card_id['comm_enc'].lstrip('\\x'))

        # DB allows not to have precise length
        customer_striped = card_id['customer_id'].lstrip('\\x')
        customer_id[ 4 - int(len(customer_striped)/2) :] = bytes.fromhex(customer_striped)

        key_version[:]  = bytes([card_id['key_version']])

        return manufacturer + mutual_auth + comm_enc + customer_id + key_version


    def serialize_PACSO(self, pacso):
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

        credential_striped = pacso['credential_id'].lstrip('\\x')
        credential_id[ 8 - int(len(credential_striped)/2) :] = bytes.fromhex(credential_striped)

        reissue_code[:]  = bytes([pacso['reissue_code']])
        # pin_code is currently not used, leave zeroes

        # DB allows to not have precise length, thus we left pad the rest
        cust_striped = pacso['customer_specific'].lstrip('\\x')
        customer_spec[ 20 - int(len(cust_striped)/2) :] = bytes.fromhex(cust_striped)

        return version_major + version_minor + site_code + credential_id + reissue_code + pin_code + customer_spec

