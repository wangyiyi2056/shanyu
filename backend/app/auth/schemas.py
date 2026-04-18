from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


class UserBase(BaseModel):
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class UserCreate(UserBase):
    google_id: Optional[str] = None
    is_guest: bool = False


class UserResponse(UserBase):
    id: str
    is_guest: bool
    created_at: datetime

    class Config:
        from_attributes = True


class GoogleAuthRequest(BaseModel):
    google_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class GuestAuthRequest(BaseModel):
    name: Optional[str] = None