from abc import ABC, abstractmethod


class Table(ABC):
    """ Base class for table functions 

    Derived classes define what needs to be done to put the system into the state as described by the database change

    Every table should have it's own class that overrides the abstract methods of this one
    """

    def __init__(self, conn, json_notification):
        """ Store the json_notification and perform needed operation based on the notification

        Args:
            json_notification (json object): already parsed notification
            conn (psycopg2.connect): psycopg2 connection object
        """

        self.notif = json_notification
        self.conn = conn
        self.parse_op()

    @abstractmethod
    def on_insert(self):
        """ What to do on INSERT into a table
        """
        pass

    @abstractmethod
    def on_update(self):
        """ What to do on UPDATE of a table
        """
        pass

    @abstractmethod
    def on_delete(self):
        """ What to do on DELETE from a table
        """
        pass

    def parse_op(self):
        """ Decide which operation has been performed
        """

        match self.notif['operation']:
            case 'INSERT':
                self.on_insert()
            
            case 'UPDATE':
                self.on_update()

            case 'DELETE':
                self.on_delete()


# TODO have a smart mechanism that will wait to push changes and handle things that override each other