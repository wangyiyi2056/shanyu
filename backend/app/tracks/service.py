import uuid
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.tracks.models import Track, TrackPoint
from app.tracks.schemas import TrackCreate, TrackUpdate, TrackPointCreate


async def create_track(
    db: AsyncSession, user_id: str, track_data: TrackCreate
) -> Track:
    track_id = str(uuid.uuid4())
    track = Track(
        id=track_id,
        user_id=user_id,
        name=track_data.name,
        start_time=track_data.start_time,
        end_time=track_data.end_time,
        total_distance=track_data.total_distance,
        duration_seconds=track_data.duration_seconds,
        elevation_gain=track_data.elevation_gain,
        elevation_loss=track_data.elevation_loss,
        is_public=track_data.is_public,
        point_count=len(track_data.points),
    )
    db.add(track)

    # Add track points
    for point in track_data.points:
        point_id = str(uuid.uuid4())
        track_point = TrackPoint(
            id=point_id,
            track_id=track_id,
            latitude=point.latitude,
            longitude=point.longitude,
            elevation=point.elevation,
            timestamp=point.timestamp,
            speed=point.speed,
        )
        db.add(track_point)

    await db.commit()
    await db.refresh(track)
    return track


async def get_track_by_id(db: AsyncSession, track_id: str) -> Optional[Track]:
    result = await db.execute(select(Track).where(Track.id == track_id))
    return result.scalar_one_or_none()


async def get_track_with_points(db: AsyncSession, track_id: str) -> Optional[dict]:
    track = await get_track_by_id(db, track_id)
    if not track:
        return None

    result = await db.execute(
        select(TrackPoint)
        .where(TrackPoint.track_id == track_id)
        .order_by(TrackPoint.timestamp.asc())
    )
    points = list(result.scalars().all())

    return {
        "track": track,
        "points": points,
    }


async def get_user_tracks(
    db: AsyncSession, user_id: str, limit: int = 20, offset: int = 0
) -> List[Track]:
    result = await db.execute(
        select(Track)
        .where(Track.user_id == user_id)
        .order_by(Track.start_time.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(result.scalars().all())


async def get_public_tracks(
    db: AsyncSession, limit: int = 20, offset: int = 0
) -> List[Track]:
    result = await db.execute(
        select(Track)
        .where(Track.is_public == True)
        .order_by(Track.start_time.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(result.scalars().all())


async def update_track(
    db: AsyncSession, track_id: str, track_data: TrackUpdate
) -> Optional[Track]:
    track = await get_track_by_id(db, track_id)
    if not track:
        return None

    update_data = track_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(track, field, value)

    await db.commit()
    await db.refresh(track)
    return track


async def delete_track(db: AsyncSession, track_id: str) -> bool:
    track = await get_track_by_id(db, track_id)
    if not track:
        return False
    await db.delete(track)
    await db.commit()
    return True


async def add_track_point(
    db: AsyncSession, track_id: str, point_data: TrackPointCreate
) -> TrackPoint:
    point_id = str(uuid.uuid4())
    point = TrackPoint(
        id=point_id,
        track_id=track_id,
        **point_data.model_dump(),
    )
    db.add(point)

    # Update track point count
    track = await get_track_by_id(db, track_id)
    if track:
        track.point_count += 1

    await db.commit()
    await db.refresh(point)
    return point


async def add_track_points_batch(
    db: AsyncSession, track_id: str, points: List[TrackPointCreate]
) -> List[TrackPoint]:
    track_points = []
    for point_data in points:
        point_id = str(uuid.uuid4())
        point = TrackPoint(
            id=point_id,
            track_id=track_id,
            **point_data.model_dump(),
        )
        db.add(point)
        track_points.append(point)

    # Update track point count
    track = await get_track_by_id(db, track_id)
    if track:
        track.point_count += len(points)

    await db.commit()
    return track_points