import asyncio
import psycopg2
from psycopg2.extras import DictCursor


def carry_out_task( payload ):
    print(payload)
    return True


async def process_tasks( conn ):
    """ Poll and process tasks from the database task_queue

    Args:
        conn (psycopg2.connect): psycopg2 connection object
    """

    while 1:
        # Just to not poll all the time
        await asyncio.sleep(0.5)

        with conn.cursor(cursor_factory=DictCursor) as cur:

            # Get the oldest task
            cur.execute("""
                SELECT id_task, task_type, payload FROM task_queue
                ORDER BY created_at
                LIMIT 1
            """)
            task = cur.fetchone()

            if not task:
                continue

            if carry_out_task(task):
                cur.execute("""
                    DELETE FROM task_queue
                    WHERE id_task = %s
                """, (task['id_task'],))
            
            else:
                pass
        


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

    asyncio.run( process_tasks(conn) )


if __name__ == '__main__':
    run_database()