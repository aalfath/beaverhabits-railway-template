"""Create the admin account on first boot, and keep its password equal to ADMIN_PASSWORD.

Runs before the web server, so the sign-up page is never open to the first visitor.
"""
import asyncio
import os
import sys

from beaverhabits.app.auth import (
    get_async_session_context,
    get_user_db_context,
    get_user_manager_context,
)
from beaverhabits.app.db import create_db_and_tables
from beaverhabits.app.schemas import UserUpdate


async def main() -> None:
    email = os.environ["ADMIN_EMAIL"].strip().lower()
    password = os.environ["ADMIN_PASSWORD"]
    await create_db_and_tables()

    async with get_async_session_context() as session:
        async with get_user_db_context(session) as user_db:
            async with get_user_manager_context(user_db) as manager:
                user = await user_db.get_by_email(email)
                if user is not None:
                    ok, _ = manager.password_helper.verify_and_update(password, user.hashed_password)
                    if not ok:
                        await manager.update(UserUpdate(password=password), user, safe=False)
                        print(f"bootstrap: password for {email} updated from ADMIN_PASSWORD")
                    else:
                        print(f"bootstrap: admin {email} already exists")
                    return

    # Same path as the sign-up page: creates the user and its starter habit list.
    from beaverhabits import views

    await views.register_user(email=email, password=password)
    print(f"bootstrap: admin {email} created")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as exc:
        print(f"bootstrap: failed: {exc!r}", file=sys.stderr)
        sys.exit(1)
