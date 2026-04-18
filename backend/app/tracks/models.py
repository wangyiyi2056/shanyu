from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database import Base


class Track(Base):
    __tablename__ = "tracks"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=True)
    total_distance = Column(Float, default=0.0)  # km
    duration_seconds = Column(Integer, default=0)
    elevation_gain = Column(Float, default=0.0)
    elevation_loss = Column(Float, default=0.0)
    point_count = Column(Integer, default=0)
    gpx_data = Column(Text, nullable=True)  # GPX XML or GeoJSON
    is_public = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User")


class TrackPoint(Base):
    __tablename__ = "track_points"

    id = Column(String, primary_key=True)
    track_id = Column(String, ForeignKey("tracks.id", ondelete="CASCADE"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    elevation = Column(Float, nullable=True)
    timestamp = Column(DateTime, nullable=False)
    speed = Column(Float, nullable=True)  # m/s

    track = relationship("Track")