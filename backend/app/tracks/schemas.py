from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class TrackPoint(BaseModel):
    latitude: float
    longitude: float
    elevation: Optional[float] = None
    timestamp: datetime
    speed: Optional[float] = None

    class Config:
        from_attributes = True


class TrackBase(BaseModel):
    name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    total_distance: float = 0.0
    duration_seconds: int = 0
    elevation_gain: float = 0.0
    elevation_loss: float = 0.0


class TrackCreate(TrackBase):
    points: List[TrackPoint] = []
    is_public: bool = False


class TrackUpdate(BaseModel):
    name: Optional[str] = None
    end_time: Optional[datetime] = None
    total_distance: Optional[float] = None
    duration_seconds: Optional[int] = None
    elevation_gain: Optional[float] = None
    elevation_loss: Optional[float] = None
    is_public: Optional[bool] = None


class TrackResponse(TrackBase):
    id: str
    user_id: str
    point_count: int = 0
    is_public: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class TrackDetailResponse(TrackResponse):
    points: List[TrackPoint] = []
    gpx_data: Optional[str] = None


class TrackPointCreate(BaseModel):
    latitude: float
    longitude: float
    elevation: Optional[float] = None
    timestamp: datetime
    speed: Optional[float] = None