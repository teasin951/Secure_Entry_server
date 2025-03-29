from .table import Table 


class Reader(Table):
    def on_insert(self):
        # TODO publish reader/<mqtt_username> or registrator/<mqtt_username>/setup and set proper ACLs
        pass

    def on_update(self):
        # TODO on id_config -> publish new config
        # TODO on id_zone -> publish new config
        # TODO on mqtt_(username, password, client id) -> update ACLs
        # TODO on registrator -> publish new config and ACLs
        # TODO on others disregard
        pass

    def on_delete(self):
        # TODO update ACLs (will disconnect the client) and clean persistent messages
        pass

