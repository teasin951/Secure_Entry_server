from .table import Table 


class Config(Table):
    def on_insert(self):
        # Do nothing, reader will use it when needed
        pass

    def on_update(self):
        # TODO check if there are readers associated with this config and update
        pass

    def on_delete(self):
        # Do nothing, cannot be deleted while there are readers using it
        pass

