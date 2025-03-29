from .table import Table 


class Zone(Table):
    def on_insert(self):
        # TODO Create ACL group for this zone
        pass

    def on_update(self):
        # Nothing to do, updates can only change name and notes
        pass

    def on_delete(self):
        # TODO Delete ACL
        # TODO Clear persistent whitelist/<zone_id>/full
        # Deletion cascades to other tables, we will receive notification there as well
        pass

