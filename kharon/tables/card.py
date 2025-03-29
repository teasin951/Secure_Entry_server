from .table import Table 
import logging


class Card(Table):
    def on_insert(self):
        # TODO send peronalization command
        # Pin code is not yet implemented in readers
        pass

    def on_update(self):
        # TODO on erase -> action depending on the value set
        # TODO on id_reader change -> send personalization command
        # TODO on UID change -> remove old from whitelists, add new to whitelists
        # Pin code is not yet implemented in readers
        pass

    def on_delete(self):
        # This should never happen as DELETE should be forbidden
        logging.critical('Received DELETE for card table, this should never happen, the database is misconfigured!')
