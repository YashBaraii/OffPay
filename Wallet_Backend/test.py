import asyncio
import asyncpg
from decouple import config


async def main():
    conn = await asyncpg.connect(
        user=config("DB_USER"),  # from Supabase
        password=config("DB_PASS"),  # your Supabase DB password
        database=config("DB_NAME"),  # default database name
        host=config("DB_HOST"),  # pooled host
        port=config("DB_PORT"),  # pooled port
        ssl="require",  # Supabase requires SSL
    )
    print("✅ Connected successfully!")

    # Example query
    rows = await conn.fetch("SELECT NOW() AS time;")
    print(rows)

    await conn.close()


asyncio.run(main())
