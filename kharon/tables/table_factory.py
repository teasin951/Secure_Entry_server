import json
from .zone import Zone
from .card import Card
from .time_rule import TimeRule
from .time_constraint import TimeConstraint
from .reader import Reader
from .config import Config
from .card_id import CardID
from .pacs_obj import PACSObject
from .card_zone import CardZone
from .card_time_rule import CardTimeRule


class TableFactory:
    """ Factory for Table objects
    """

    @staticmethod
    def create_table( conn, notification ):
        """ Create Table object based on table that sent the notification

        Args:
            notification (raw notification PAYLOAD): as received from conn.notifies
            conn (psycopg2.connect): psycopg2 connection object
        """

        parsed = json.loads(notification)
        match parsed['table']:
            case 'card':
                return Card(conn, parsed)

            case 'zone':
                return Zone(conn, parsed)

            case 'time_rule':
                return TimeRule(conn, parsed)

            case 'time_constraint':
                return TimeConstraint(conn,parsed)

            case 'reader':
                return Reader(conn, parsed)

            case 'config':
                return Config(conn, parsed)

            case 'card_identifier':
                return CardID(conn, parsed)

            case 'pacs_object':
                return PACSObject(conn, parsed)

            case 'card_zone':
                return CardZone(conn, parsed)

            case 'card_time_rule':
                return CardTimeRule(conn, parsed)