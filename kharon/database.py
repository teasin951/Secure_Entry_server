import asyncio
import psycopg2
from psycopg2.extras import DictCursor
from mqtt import MQTTHandler
from task_types import carry_out_task


def query_task_queue(cur, mqtthandler:MQTTHandler):
    # Get the oldest task
    cur.execute("""
        SELECT count(*) OVER () AS in_queue, id_task, task_type, payload 
        FROM task_queue
        ORDER BY created_at, id_task
        LIMIT 1;
    """)
    task = cur.fetchone()

    if not task:
        return 0

    if carry_out_task(task, mqtthandler):
        cur.execute("""
            DELETE FROM task_queue
            WHERE id_task = %s;
        """, (task['id_task'],))
    
    # TODO handle failure somehow

    return task['in_queue']


async def process_tasks(conn, mqtthandler:MQTTHandler):
    """ Poll and process tasks from the database task_queue

    Args:
        conn (psycopg2.connect): psycopg2 connection object
    """

    tasks_in_queue = 0

    while 1:
        # Just to not poll all the time, but don't wait if there are tasks waiting
        if(tasks_in_queue == 0):
            await asyncio.sleep(0.5)

        with conn.cursor(cursor_factory=DictCursor) as cur:
            try:
                tasks_in_queue = query_task_queue(cur, mqtthandler)

            except psycopg2.Error as e:
                print("Database error: ", e)
                print("Reatempting in 10 s\n")
                await asyncio.sleep(10)
        

def run_database(mqtthandler:MQTTHandler):
    """ Connect to the specified database and listen for notifications
    """

    conn = psycopg2.connect(
        host="localhost", 
        dbname="test", 
        user="admin", 
        password="admin"
    )
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

    asyncio.run( process_tasks(conn, mqtthandler) )

    return conn


if __name__ == '__main__':
    run_database()