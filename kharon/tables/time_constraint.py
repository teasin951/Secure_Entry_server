from .table import Table 


class TimeConstraint(Table):
    def on_insert(self):
        # TODO check if the associated time rule has any cards associated and update the whitelist
        pass

    def on_update(self):
        # TODO check if the associated time rule has any cards associated and update the whitelist
        pass

    def on_delete(self):
        # TODO check if the associated time rule has any cards associated and update the whitelist
        pass

