from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List


class AchievementBase(BaseModel):
    type: str
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None


class AchievementResponse(AchievementBase):
    id: str
    user_id: str
    earned_at: datetime

    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class UserProfileResponse(BaseModel):
    id: str
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    is_guest: bool
    created_at: datetime
    favorites_count: int = 0
    tracks_count: int = 0
    achievements: List[AchievementResponse] = []

    class Config:
        from_attributes = True