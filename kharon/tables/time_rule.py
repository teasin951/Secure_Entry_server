from .table import Table 


class TimeRule(Table):
    def on_insert(self):
        # Do nothing, it has to be assigned first to have any effect
        pass

    def on_update(self):
        # Do nothing, id_zone and id_time_rule are identifying - cannot be changed - name and notes are unimportant
        pass

    def on_delete(self):
        # TODO update whitelist
        #      after this the delete will cascade to time_constraints, but when they will try to select dependencies
        #      there won't be any, thus nothing will happen
        pass

