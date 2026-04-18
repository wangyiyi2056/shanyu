import uuid
from typing import Optional, List
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.users.models import Achievement, favorites
from app.users.schemas import AchievementBase, UserProfileUpdate
from app.auth.models import User
from app.routes.models import Route
from app.tracks.models import Track


async def get_user_profile(db: AsyncSession, user_id: str) -> Optional[dict]:
    """Get user profile with stats."""
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    # Count favorites
    fav_result = await db.execute(
        select(func.count()).where(favorites.c.user_id == user_id)
    )
    favorites_count = fav_result.scalar() or 0

    # Count tracks
    tracks_result = await db.execute(
        select(func.count()).where(Track.user_id == user_id)
    )
    tracks_count = tracks_result.scalar() or 0

    # Get achievements
    achievements_result = await db.execute(
        select(Achievement).where(Achievement.user_id == user_id)
    )
    achievements = list(achievements_result.scalars().all())

    return {
        "user": user,
        "favorites_count": favorites_count,
        "tracks_count": tracks_count,
        "achievements": achievements,
    }


async def update_user_profile(
    db: AsyncSession, user_id: str, profile_data: UserProfileUpdate
) -> Optional[User]:
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    update_data = profile_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    await db.commit()
    await db.refresh(user)
    return user


async def get_user_favorites(db: AsyncSession, user_id: str) -> List[Route]:
    """Get user's favorite routes."""
    result = await db.execute(
        select(Route)
        .join(favorites, Route.id == favorites.c.route_id)
        .where(favorites.c.user_id == user_id)
        .order_by(Route.rating.desc())
    )
    return list(result.scalars().all())


async def add_favorite(db: AsyncSession, user_id: str, route_id: str) -> bool:
    """Add route to favorites."""
    # Check if route exists
    route_result = await db.execute(select(Route).where(Route.id == route_id))
    route = route_result.scalar_one_or_none()
    if not route:
        return False

    # Check if already favorited
    existing = await db.execute(
        select(favorites).where(
            favorites.c.user_id == user_id,
            favorites.c.route_id == route_id,
        )
    )
    if existing.scalar_one_or_none():
        return True  # Already exists

    # Add favorite
    await db.execute(
        favorites.insert().values(user_id=user_id, route_id=route_id)
    )
    await db.commit()
    return True


async def remove_favorite(db: AsyncSession, user_id: str, route_id: str) -> bool:
    """Remove route from favorites."""
    result = await db.execute(
        favorites.delete().where(
            favorites.c.user_id == user_id,
            favorites.c.route_id == route_id,
        )
    )
    await db.commit()
    return result.rowcount > 0


async def get_user_achievements(db: AsyncSession, user_id: str) -> List[Achievement]:
    """Get user's achievements."""
    result = await db.execute(
        select(Achievement)
        .where(Achievement.user_id == user_id)
        .order_by(Achievement.earned_at.desc())
    )
    return list(result.scalars().all())


async def grant_achievement(
    db: AsyncSession, user_id: str, achievement_data: AchievementBase
) -> Achievement:
    """Grant achievement to user."""
    achievement_id = str(uuid.uuid4())
    achievement = Achievement(
        id=achievement_id,
        user_id=user_id,
        **achievement_data.model_dump(),
    )
    db.add(achievement)
    await db.commit()
    await db.refresh(achievement)
    return achievement