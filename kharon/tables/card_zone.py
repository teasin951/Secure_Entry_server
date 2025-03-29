from .table import Table 


class CardZone(Table):
    def on_insert(self):
        # TODO add card to whitelist
        pass

    def on_update(self):
        # TODO remove old, add new to whitelist
        pass

    def on_delete(self):
        # TODO remove from whitelist
        pass

