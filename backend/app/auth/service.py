from datetime import datetime, timedelta
from typing import Optional
import httpx
from jose import jwt, JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.auth.models import User
from app.auth.schemas import UserCreate, UserResponse

settings = get_settings()


def create_access_token(user_id: str, is_guest: bool = False) -> str:
    expire = datetime.utcnow() + timedelta(hours=settings.jwt_expiration_hours)
    payload = {
        "sub": user_id,
        "is_guest": is_guest,
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def verify_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        return payload
    except JWTError:
        return None


async def verify_google_token(token: str) -> Optional[dict]:
    """Verify Google OAuth token using Google's tokeninfo endpoint."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://oauth2.googleapis.com/tokeninfo",
                params={"id_token": token},
                timeout=10.0,
            )
            if response.status_code == 200:
                data = response.json()
                # Verify the token was issued for our client
                if settings.google_client_id:
                    if data.get("aud") != settings.google_client_id:
                        return None
                return data
    except Exception:
        pass
    return None


async def get_or_create_user_from_google(
    db: AsyncSession, google_data: dict
) -> User:
    """Get existing user or create new one from Google OAuth data."""
    google_id = google_data.get("sub")
    email = google_data.get("email")
    name = google_data.get("name")
    avatar_url = google_data.get("picture")

    # Try to find existing user by google_id
    result = await db.execute(select(User).where(User.google_id == google_id))
    user = result.scalar_one_or_none()

    if user:
        # Update user info
        user.name = name
        user.avatar_url = avatar_url
        user.email = email
        await db.commit()
        await db.refresh(user)
        return user

    # Try to find by email
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if user:
        # Link Google account
        user.google_id = google_id
        user.name = name
        user.avatar_url = avatar_url
        await db.commit()
        await db.refresh(user)
        return user

    # Create new user
    user = User(
        id=f"google_{google_id}",
        google_id=google_id,
        email=email,
        name=name,
        avatar_url=avatar_url,
        is_guest=False,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def create_guest_user(db: AsyncSession, name: Optional[str] = None) -> User:
    """Create a guest user without Google OAuth."""
    import uuid
    guest_id = f"guest_{uuid.uuid4().hex[:12]}"

    user = User(
        id=guest_id,
        name=name or "Guest User",
        is_guest=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()