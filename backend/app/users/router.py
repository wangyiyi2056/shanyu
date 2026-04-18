from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.auth.router import get_current_user
from app.users.schemas import UserProfileUpdate, UserProfileResponse, AchievementResponse
from app.users.service import (
    get_user_profile,
    update_user_profile,
    get_user_favorites,
    add_favorite,
    remove_favorite,
    get_user_achievements,
)
from app.routes.schemas import RouteResponse

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Get current user's profile."""
    profile = await get_user_profile(db, user.id)
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return UserProfileResponse(
        id=profile["user"].id,
        email=profile["user"].email,
        name=profile["user"].name,
        avatar_url=profile["user"].avatar_url,
        is_guest=profile["user"].is_guest,
        created_at=profile["user"].created_at,
        favorites_count=profile["favorites_count"],
        tracks_count=profile["tracks_count"],
        achievements=[AchievementResponse.model_validate(a) for a in profile["achievements"]],
    )


@router.put("/me", response_model=UserProfileResponse)
async def update_my_profile(
    profile_data: UserProfileUpdate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Update current user's profile."""
    updated_user = await update_user_profile(db, user.id, profile_data)
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    profile = await get_user_profile(db, user.id)
    return UserProfileResponse(
        id=profile["user"].id,
        email=profile["user"].email,
        name=profile["user"].name,
        avatar_url=profile["user"].avatar_url,
        is_guest=profile["user"].is_guest,
        created_at=profile["user"].created_at,
        favorites_count=profile["favorites_count"],
        tracks_count=profile["tracks_count"],
        achievements=[AchievementResponse.model_validate(a) for a in profile["achievements"]],
    )


@router.get("/me/favorites", response_model=List[RouteResponse])
async def get_my_favorites(
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Get current user's favorite routes."""
    favorites = await get_user_favorites(db, user.id)
    return [RouteResponse.model_validate(r) for r in favorites]


@router.post("/me/favorites/{route_id}", status_code=status.HTTP_201_CREATED)
async def add_to_favorites(
    route_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Add route to favorites."""
    success = await add_favorite(db, user.id, route_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    return {"message": "Added to favorites"}


@router.delete("/me/favorites/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_favorites(
    route_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Remove route from favorites."""
    success = await remove_favorite(db, user.id, route_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Favorite not found",
        )


@router.get("/me/achievements", response_model=List[AchievementResponse])
async def get_my_achievements(
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Get current user's achievements."""
    achievements = await get_user_achievements(db, user.id)
    return [AchievementResponse.model_validate(a) for a in achievements]