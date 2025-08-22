from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from decouple import config

DATABASE_URL = config("SUPABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
