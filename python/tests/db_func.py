import psycopg2
from psycopg2.extras import DictCursor


def convert_memoryviews_to_bytes(data):
    """Recursively convert memoryview objects to bytes in query results.
    """

    if isinstance(data, memoryview):
        return data.tobytes()
    elif isinstance(data, tuple):
        return tuple(convert_memoryviews_to_bytes(item) for item in data)
    elif isinstance(data, list):
        return [convert_memoryviews_to_bytes(item) for item in data]
    else:
        return data


class AssertDB:
    def __init__(self, host, dbname, username, password):
        """ Simple testing class

        Args:
            host (string): host name of the database
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


    def assert_query_success(self, query, test_name=""):
        """ Test that a query is successful

        Args:
            query (string): query to send
            test_name (string): optional test name
        """

        with self.conn.cursor(cursor_factory=DictCursor) as cur:
            try:
                cur.execute(query)

            except psycopg2.Error as e:
                assert False, f"-- {test_name} --\nQuery: {query}\nExpected success but failed. Error: {e}"


    def assert_query_fail(self, query, test_name=""):
        """ Test for exception on query

        Args:
            query (string): query to send
            test_name (string): optional test name
        """

        with self.conn.cursor(cursor_factory=DictCursor) as cur:
            try:
                cur.execute(query)
                assert False, f"-- {test_name} --\nQuery: {query}\nExpected error but succeeded"

            except psycopg2.Error:
                pass


    def assert_query_response(self, query, expect, test_name=""):
        """ Test that a query response makes sense

        Args:
            query (string): query to send
            expect (tuple array): what should be returned
            test_name (string): optional test name
        """

        with self.conn.cursor() as cur:
            try:
                cur.execute(query)
                res = cur.fetchall()

                proc_res = convert_memoryviews_to_bytes(res)
                assert proc_res == expect, f"-- {test_name} --\nQuery: {query}\nExpected: {expect}\nGot: {proc_res}"

            except psycopg2.Error as e:
                assert False, f"-- {test_name} --\nQuery: {query}\nExpected success but failed. Error: {e}"


    def assert_query_response_not_null(self, query, test_name=""):
        """ Test that a query response is not empty

        Args:
            query (string): query to send
            test_name (string): optional test name
        """

        with self.conn.cursor() as cur:
            try:
                cur.execute(query)
                res = cur.fetchall()
                proc_res = convert_memoryviews_to_bytes(res)

                print(f"Got: {proc_res}")
                assert proc_res != [], f"-- {test_name} --\nQuery: {query}\nExpected something but got nothing"

            except psycopg2.Error as e:
                assert False, f"-- {test_name} --\nQuery: {query}\nExpected success but failed. Error: {e}"


    def assert_query_response_null(self, query, test_name=""):
        """ Test that a query response is empty

        Args:
            query (string): query to send
            test_name (string): optional test name
        """

        with self.conn.cursor() as cur:
            try:
                cur.execute(query)
                res = cur.fetchall()
                proc_res = convert_memoryviews_to_bytes(res)

                print(f"Got: {proc_res}")
                assert proc_res == [], f"-- {test_name} --\nQuery: {query}\nExpected nothing but got: {proc_res}"

            except psycopg2.Error as e:
                assert False, f"-- {test_name} --\nQuery: {query}\nExpected success but failed. Error: {e}"



