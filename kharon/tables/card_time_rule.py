from .table import Table 


class CardTimeRule(Table):
    def on_insert(self):
        # TODO add to whitelist
        pass

    def on_update(self):
        # TODO remove old, add new rule to whitelist
        pass

    def on_delete(self):
        # TODO remove from whitelist
        pass

