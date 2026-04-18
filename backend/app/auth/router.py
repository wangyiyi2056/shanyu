from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.auth.schemas import (
    GoogleAuthRequest,
    GuestAuthRequest,
    TokenResponse,
    UserResponse,
)
from app.auth.service import (
    create_access_token,
    verify_token,
    verify_google_token,
    get_or_create_user_from_google,
    create_guest_user,
    get_user_by_id,
)

router = APIRouter(prefix="/auth", tags=["auth"])
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
):
    token = credentials.credentials
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    user_id = payload.get("sub")
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user


@router.post("/google", response_model=TokenResponse)
async def auth_with_google(
    request: GoogleAuthRequest,
    db: AsyncSession = Depends(get_db),
):
    """Authenticate with Google OAuth token."""
    google_data = await verify_google_token(request.google_token)
    if not google_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token",
        )

    user = await get_or_create_user_from_google(db, google_data)
    access_token = create_access_token(user.id, user.is_guest)

    return TokenResponse(
        access_token=access_token,
        user=UserResponse.model_validate(user),
    )


@router.post("/guest", response_model=TokenResponse)
async def auth_as_guest(
    request: GuestAuthRequest = GuestAuthRequest(),
    db: AsyncSession = Depends(get_db),
):
    """Create a guest user session."""
    user = await create_guest_user(db, request.name)
    access_token = create_access_token(user.id, is_guest=True)

    return TokenResponse(
        access_token=access_token,
        user=UserResponse.model_validate(user),
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    user = Depends(get_current_user),
):
    """Get current authenticated user info."""
    return UserResponse.model_validate(user)