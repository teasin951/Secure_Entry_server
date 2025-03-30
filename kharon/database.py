import asyncio
import psycopg2


async def handle_notify( conn ):
    """ Async task waiting for notifications

    Args:
        conn (psycopg2.connect): psycopg2 connection object
    """

    while 1:
        conn.poll()
        for notify in conn.notifies:
            # TODO
            pass
        conn.notifies.clear()
        await asyncio.sleep(0.5)


def run_database():
    """ Connect to the specified database and listen for notifications
    """

    conn = psycopg2.connect(
        host="localhost", 
        dbname="test", 
        user="admin", 
        password="admin"
    )
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

    cursor = conn.cursor()
    cursor.execute("LISTEN database_operation;")

    asyncio.run( handle_notify(conn) )


if __name__ == '__main__':
    run_database()