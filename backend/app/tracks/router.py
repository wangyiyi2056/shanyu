from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.auth.router import get_current_user
from app.tracks.schemas import (
    TrackCreate,
    TrackUpdate,
    TrackResponse,
    TrackDetailResponse,
    TrackPointCreate,
    TrackPoint,
)
from app.tracks.service import (
    create_track,
    get_track_by_id,
    get_track_with_points,
    get_user_tracks,
    get_public_tracks,
    update_track,
    delete_track,
    add_track_point,
    add_track_points_batch,
)

router = APIRouter(prefix="/tracks", tags=["tracks"])


@router.get("", response_model=List[TrackResponse])
async def list_user_tracks(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """List user's tracks."""
    tracks = await get_user_tracks(db, user.id, limit, offset)
    return [TrackResponse.model_validate(t) for t in tracks]


@router.get("/public", response_model=List[TrackResponse])
async def list_public_tracks(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """List public tracks."""
    tracks = await get_public_tracks(db, limit, offset)
    return [TrackResponse.model_validate(t) for t in tracks]


@router.get("/public/{track_id}", response_model=TrackDetailResponse)
async def get_public_track_detail(
    track_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get public track details with points (no auth required)."""
    data = await get_track_with_points(db, track_id)
    if not data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found",
        )

    track = data["track"]
    points = data["points"]

    # Only allow access to public tracks
    if not track.is_public:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This track is not public",
        )

    return TrackDetailResponse(
        id=track.id,
        user_id=track.user_id,
        name=track.name,
        start_time=track.start_time,
        end_time=track.end_time,
        total_distance=track.total_distance,
        duration_seconds=track.duration_seconds,
        elevation_gain=track.elevation_gain,
        elevation_loss=track.elevation_loss,
        point_count=track.point_count,
        is_public=track.is_public,
        created_at=track.created_at,
        points=[TrackPoint.model_validate(p) for p in points],
        gpx_data=track.gpx_data,
    )


@router.get("/{track_id}", response_model=TrackDetailResponse)
async def get_track(
    track_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Get track details with points."""
    data = await get_track_with_points(db, track_id)
    if not data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found",
        )

    track = data["track"]
    points = data["points"]

    # Check access: owner or public
    if track.user_id != user.id and not track.is_public:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this track",
        )

    return TrackDetailResponse(
        id=track.id,
        user_id=track.user_id,
        name=track.name,
        start_time=track.start_time,
        end_time=track.end_time,
        total_distance=track.total_distance,
        duration_seconds=track.duration_seconds,
        elevation_gain=track.elevation_gain,
        elevation_loss=track.elevation_loss,
        point_count=track.point_count,
        is_public=track.is_public,
        created_at=track.created_at,
        points=[TrackPoint.model_validate(p) for p in points],
        gpx_data=track.gpx_data,
    )


@router.post("", response_model=TrackResponse, status_code=status.HTTP_201_CREATED)
async def create_new_track(
    track_data: TrackCreate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Create a new track."""
    track = await create_track(db, user.id, track_data)
    return TrackResponse.model_validate(track)


@router.put("/{track_id}", response_model=TrackResponse)
async def update_existing_track(
    track_id: str,
    track_data: TrackUpdate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Update a track."""
    track = await get_track_by_id(db, track_id)
    if not track:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found",
        )
    if track.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this track",
        )
    updated_track = await update_track(db, track_id, track_data)
    return TrackResponse.model_validate(updated_track)


@router.delete("/{track_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_track(
    track_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Delete a track."""
    track = await get_track_by_id(db, track_id)
    if not track:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found",
        )
    if track.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this track",
        )
    await delete_track(db, track_id)


@router.post("/{track_id}/points", status_code=status.HTTP_201_CREATED)
async def add_points_to_track(
    track_id: str,
    points: List[TrackPointCreate],
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Add points to an existing track."""
    track = await get_track_by_id(db, track_id)
    if not track:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found",
        )
    if track.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this track",
        )
    await add_track_points_batch(db, track_id, points)
    return {"message": f"Added {len(points)} points"}