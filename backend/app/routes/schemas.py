from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class Waypoint(BaseModel):
    id: str
    name: str
    type: str  # start, end, landmark, viewpoint, rest_area, danger
    latitude: float
    longitude: float
    elevation: Optional[float] = None


class RouteBase(BaseModel):
    name: str
    location: str
    description: Optional[str] = None
    distance: float = 0.0
    elevation_gain: float = 0.0
    max_elevation: float = 0.0
    estimated_duration: int = 0
    difficulty: str = "moderate"
    surface_type: str = "mixed"
    tags: List[str] = []
    waypoints: List[Waypoint] = []
    warnings: List[str] = []
    best_seasons: List[str] = []
    image_url: Optional[str] = None


class RouteCreate(RouteBase):
    pass


class RouteUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None
    distance: Optional[float] = None
    elevation_gain: Optional[float] = None
    max_elevation: Optional[float] = None
    estimated_duration: Optional[int] = None
    difficulty: Optional[str] = None
    surface_type: Optional[str] = None
    tags: Optional[List[str]] = None
    waypoints: Optional[List[Waypoint]] = None
    warnings: Optional[List[str]] = None
    best_seasons: Optional[List[str]] = None
    image_url: Optional[str] = None


class RouteResponse(RouteBase):
    id: str
    rating: float = 0.0
    review_count: int = 0
    created_by: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ReviewBase(BaseModel):
    rating: int  # 1-5
    content: Optional[str] = None


class ReviewCreate(ReviewBase):
    pass


class ReviewResponse(ReviewBase):
    id: str
    route_id: str
    user_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class RouteSearchParams(BaseModel):
    query: Optional[str] = None
    difficulty: Optional[str] = None
    max_duration: Optional[int] = None  # minutes
    max_distance: Optional[float] = None  # km
    tags: Optional[List[str]] = None