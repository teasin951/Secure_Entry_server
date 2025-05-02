import json
import psycopg2
from psycopg2.extras import DictCursor


class TestDB:
    def __init__(self, host, dbname, username, password):
        """ Simple testing class

        Args:
            host (strign): host name of the database
            dbname (string): name of the database
            username (string): username to log in with
            password (string): password for the user
        """

        self.conn = psycopg2.connect(
            host=host, 
            dbname=dbname, 
            user=username, 
            password=password
        )
        self.conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)


def test_query_success(self, query, test_name=""):
    """ Test that a query is sucessful

    Args:
        query (string): query to send
        test_name (string): optional test name
    """

    with self.conn.cursor(cursor_factory=DictCursor) as cur:
        try:
            cur.execute(query)
        except psycopg2:
            assert False, format("-- %s --\nQuery: %s failed", test_name, query)


def test_query_fail(self, query, test_name=""):
    """ Test for exception on query

    Args:
        query (string): query to send
        test_name (string): optional test name
    """

    with self.conn.cursor(cursor_factory=DictCursor) as cur:
        try:
            cur.execute(query)
            assert False, format("-- %s --\nQuery: %s succeeded", test_name, query)
        except psycopg2:
            pass


def test_task_queue(self, task_type, payload, test_name=""):
    """ Test content on the task queue

    Args:
        task_type (string): expected type
        payload (dictionary): expected payload
        test_name (string): optional test name
    """

    with self.conn.cursor(cursor_factory=DictCursor) as cur:
        try:
            cur.execute("""
                SELECT * FROM task_queue ORDER BY created_at, id_task LIMIT 1
            """)
            task = cur.fetchone()
            dict_task = json.loads(task['payload'])

            assert dict_task == payload, format("-- %s --\nTask queue does not match.\nGot: %s | %s\n Expected: %s | %s\n", 
                test_name, task['task_type'], task['payload'], task_type, payload)
        except psycopg2:
            assert False, "Selecting from task_queue failed"